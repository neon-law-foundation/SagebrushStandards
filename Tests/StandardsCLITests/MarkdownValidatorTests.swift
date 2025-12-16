import Foundation
import Testing

@testable import StandardsCLI

@Suite("Markdown Validator")
struct MarkdownValidatorTests {
    let validator = MarkdownValidator()

    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("StandardsCLITests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanupTestDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Valid file with short lines passes validation")
    func validFileWithShortLines() throws {
        let testFixturesURL = try createTestDirectory()
        defer { cleanupTestDirectory(testFixturesURL) }

        let fileURL = testFixturesURL.appendingPathComponent("valid.md")
        let content = """
            # Short Title

            This is a line with less than 120 characters.
            Another short line.
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.isEmpty)
    }

    @Test("Valid file with exactly 120 characters passes validation")
    func validFileWithExactly120Characters() throws {
        let testFixturesURL = try createTestDirectory()
        defer { cleanupTestDirectory(testFixturesURL) }

        let fileURL = testFixturesURL.appendingPathComponent("exact.md")
        // Create a line with exactly 120 characters
        let line120 = String(repeating: "a", count: 120)
        let content = """
            # Title

            \(line120)
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.isEmpty)
    }

    @Test("Invalid file with long line fails validation")
    func invalidFileWithLongLine() throws {
        let testFixturesURL = try createTestDirectory()
        defer { cleanupTestDirectory(testFixturesURL) }

        let fileURL = testFixturesURL.appendingPathComponent("invalid.md")
        // Create a line with 121 characters
        let line121 = String(repeating: "a", count: 121)
        let content = """
            # Title

            \(line121)
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 1)
        #expect(violations[0].lineNumber == 3)
        #expect(violations[0].length == 121)
        #expect(violations[0].maxLength == 120)
    }

    @Test("Invalid file with multiple long lines fails validation")
    func invalidFileWithMultipleLongLines() throws {
        let testFixturesURL = try createTestDirectory()
        defer { cleanupTestDirectory(testFixturesURL) }

        let fileURL = testFixturesURL.appendingPathComponent("multiple-invalid.md")
        let line150 = String(repeating: "x", count: 150)
        let line130 = String(repeating: "y", count: 130)
        let content = """
            # Title

            \(line150)
            Short line here.
            \(line130)
            Another short line.
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 2)
        #expect(violations[0].lineNumber == 3)
        #expect(violations[0].length == 150)
        #expect(violations[1].lineNumber == 5)
        #expect(violations[1].length == 130)
    }

    @Test("Directory validation finds all invalid files")
    func directoryValidationFindsAllInvalidFiles() throws {
        let testFixturesURL = try createTestDirectory()
        defer { cleanupTestDirectory(testFixturesURL) }

        // Create nested directory structure
        let subdir = testFixturesURL.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        // Valid file in root
        let validFile = testFixturesURL.appendingPathComponent("valid.md")
        try "# Short content".write(to: validFile, atomically: true, encoding: .utf8)

        // Invalid file in root
        let invalidFile1 = testFixturesURL.appendingPathComponent("invalid1.md")
        let longLine = String(repeating: "a", count: 150)
        try "# Title\n\n\(longLine)".write(to: invalidFile1, atomically: true, encoding: .utf8)

        // Invalid file in subdirectory
        let invalidFile2 = subdir.appendingPathComponent("invalid2.md")
        try "# Title\n\n\(longLine)".write(to: invalidFile2, atomically: true, encoding: .utf8)

        // Non-markdown file (should be ignored)
        let txtFile = testFixturesURL.appendingPathComponent("ignored.txt")
        try longLine.write(to: txtFile, atomically: true, encoding: .utf8)

        let result = try validator.validate(directory: testFixturesURL)
        #expect(!result.isValid)
        #expect(result.violations.count == 2)
    }

    @Test("Directory with only valid files passes validation")
    func directoryWithOnlyValidFilesPassesValidation() throws {
        let testFixturesURL = try createTestDirectory()
        defer { cleanupTestDirectory(testFixturesURL) }

        let file1 = testFixturesURL.appendingPathComponent("file1.md")
        let file2 = testFixturesURL.appendingPathComponent("file2.md")

        try "# Short content 1".write(to: file1, atomically: true, encoding: .utf8)
        try "# Short content 2".write(to: file2, atomically: true, encoding: .utf8)

        let result = try validator.validate(directory: testFixturesURL)
        #expect(result.isValid)
        #expect(result.violations.isEmpty)
    }

    @Test("Empty file passes validation")
    func emptyFilePassesValidation() throws {
        let testFixturesURL = try createTestDirectory()
        defer { cleanupTestDirectory(testFixturesURL) }

        let fileURL = testFixturesURL.appendingPathComponent("empty.md")
        try "".write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.isEmpty)
    }

    @Test("README.md files are excluded from validation")
    func readmeFilesAreExcluded() throws {
        let testFixturesURL = try createTestDirectory()
        defer { cleanupTestDirectory(testFixturesURL) }

        let readmeURL = testFixturesURL.appendingPathComponent("README.md")
        let longLine = String(repeating: "a", count: 150)
        try "# README\n\n\(longLine)".write(to: readmeURL, atomically: true, encoding: .utf8)

        let result = try validator.validate(directory: testFixturesURL)
        #expect(result.isValid)
        #expect(result.violations.isEmpty)
    }

    @Test("Validation throws error for non-existent file")
    func validationThrowsErrorForNonExistentFile() throws {
        let testFixturesURL = try createTestDirectory()
        defer { cleanupTestDirectory(testFixturesURL) }

        let nonExistentURL = testFixturesURL.appendingPathComponent("does-not-exist.md")

        #expect(throws: ValidationError.self) {
            try validator.validateFile(at: nonExistentURL)
        }
    }
}
