import Foundation
import Testing

@testable import StandardsCLI

@Suite("F101: Title Required")
struct F101_TitleRequiredTests {
    let rule = F101_TitleRequired()

    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "F101Tests-\(UUID().uuidString)"
        )
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanupTestDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Valid file with title in frontmatter has no F101 violations")
    func validFileWithTitleInFrontmatter() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("valid.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: person
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.isEmpty)

        cleanupTestDirectory(testDir)
    }

    @Test("File without frontmatter generates F101 violation")
    func fileWithoutFrontmatterGeneratesF101Violation() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("no-frontmatter.md")
        let content = """
            # Content here

            This file has no frontmatter at all.
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F101")
        #expect(violations[0].message == "Missing frontmatter with title field")

        cleanupTestDirectory(testDir)
    }

    @Test("File with empty frontmatter generates F101 violation")
    func fileWithEmptyFrontmatterGeneratesF101Violation() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("empty-frontmatter.md")
        let content = """
            ---
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F101")
        #expect(
            violations[0].message == "Frontmatter must contain a non-empty title field"
        )

        cleanupTestDirectory(testDir)
    }

    @Test("File with frontmatter but no title field generates F101 violation")
    func fileWithFrontmatterButNoTitleGeneratesF101Violation() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("no-title.md")
        let content = """
            ---
            author: John Doe
            date: 2025-12-20
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F101")
        #expect(
            violations[0].message == "Frontmatter must contain a non-empty title field"
        )

        cleanupTestDirectory(testDir)
    }

    @Test("File with empty title value generates F101 violation")
    func fileWithEmptyTitleValueGeneratesF101Violation() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("empty-title.md")
        let content = """
            ---
            title:
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F101")
        #expect(
            violations[0].message == "Frontmatter must contain a non-empty title field"
        )

        cleanupTestDirectory(testDir)
    }

    @Test("File with whitespace-only title generates F101 violation")
    func fileWithWhitespaceOnlyTitleGeneratesF101Violation() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("whitespace-title.md")
        let content = """
            ---
            title:
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F101")
        #expect(
            violations[0].message == "Frontmatter must contain a non-empty title field"
        )

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
