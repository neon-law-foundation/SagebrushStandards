import Foundation
import Testing

@testable import StandardsCLI

@Suite("S101: Line Length")
struct S101_LineLengthTests {
    let rule = S101_LineLength()

    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "StandardsCLITests-\(UUID().uuidString)"
        )
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanupTestDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Valid file with short lines has no violations")
    func validFileWithShortLines() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("valid.md")
        let content = """
            # Short Title

            This is a line with less than 120 characters.
            Another short line.
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.isEmpty)

        cleanupTestDirectory(testDir)
    }

    @Test("Valid file with exactly 120 characters has no violations")
    func validFileWithExactly120Characters() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("exact.md")
        let line120 = String(repeating: "a", count: 120)
        let content = """
            # Title

            \(line120)
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.isEmpty)

        cleanupTestDirectory(testDir)
    }

    @Test("Invalid file with 121 character line generates S101 violation")
    func invalidFileWithLongLine() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("invalid.md")
        let line121 = String(repeating: "a", count: 121)
        let content = """
            # Title

            \(line121)
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "S101")
        #expect(violations[0].line == 3)
        #expect(violations[0].message == "Line exceeds maximum length")
        #expect(violations[0].context?["length"] == "121")
        #expect(violations[0].context?["max"] == "120")

        cleanupTestDirectory(testDir)
    }

    @Test("Invalid file with multiple long lines generates multiple S101 violations")
    func invalidFileWithMultipleLongLines() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("multiple-invalid.md")
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

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 2)
        #expect(violations[0].ruleCode == "S101")
        #expect(violations[0].line == 3)
        #expect(violations[0].context?["length"] == "150")
        #expect(violations[1].ruleCode == "S101")
        #expect(violations[1].line == 5)
        #expect(violations[1].context?["length"] == "130")

        cleanupTestDirectory(testDir)
    }

    @Test("Empty file has no violations")
    func emptyFileHasNoViolations() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("empty.md")
        try "".write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.isEmpty)

        cleanupTestDirectory(testDir)
    }

    @Test("Validation throws error for non-existent file")
    func validationThrowsErrorForNonExistentFile() throws {
        let testDir = try createTestDirectory()

        let nonExistentURL = testDir.appendingPathComponent("does-not-exist.md")

        #expect(throws: ValidationError.self) {
            try rule.validate(file: nonExistentURL)
        }

        cleanupTestDirectory(testDir)
    }
}
