import Foundation
import Testing

@testable import StandardsCLI

@Suite("Rule Engine")
struct RuleEngineTests {
    @Test("Engine lints directory with no violations")
    func engineLintsDirectoryWithNoViolations() throws {
        let testDir = try createTestDirectory()

        let validContent = """
            ---
            title: Test Document
            respondent_type: person
            ---

            # Test

            This is a short line.
            """

        try validContent.write(
            to: testDir.appendingPathComponent("test.md"),
            atomically: true,
            encoding: .utf8
        )

        let engine = RuleEngine(rules: [
            S101_LineLength(),
            F101_TitleRequired(),
            F102_RespondentTypeRequired(),
        ])

        let result = try engine.lint(directory: testDir)

        #expect(result.isValid)
        #expect(result.totalViolationCount == 0)
        #expect(result.fileViolations.isEmpty)

        try cleanupTestDirectory(testDir)
    }

    @Test("Engine collects violations from multiple rules")
    func engineCollectsViolationsFromMultipleRules() throws {
        let testDir = try createTestDirectory()

        let longLine = String(repeating: "a", count: 121)
        let invalidContent = """
            # No frontmatter

            \(longLine)
            """

        try invalidContent.write(
            to: testDir.appendingPathComponent("test.md"),
            atomically: true,
            encoding: .utf8
        )

        let engine = RuleEngine(rules: [
            S101_LineLength(),
            F101_TitleRequired(),
            F102_RespondentTypeRequired(),
        ])

        let result = try engine.lint(directory: testDir)

        #expect(!result.isValid)
        #expect(result.totalViolationCount == 3)
        #expect(result.fileViolations.count == 1)

        let fileViolation = result.fileViolations[0]
        #expect(fileViolation.violations.count == 3)

        let ruleCodes = fileViolation.violations.map { $0.ruleCode }.sorted()
        #expect(ruleCodes == ["F101", "F102", "S101"])

        try cleanupTestDirectory(testDir)
    }

    @Test("Engine lints multiple files")
    func engineLintsMultipleFiles() throws {
        let testDir = try createTestDirectory()

        let validContent = """
            ---
            title: Valid Document
            respondent_type: entity
            ---

            Short line.
            """

        let invalidContent = """
            # No frontmatter
            """

        try validContent.write(
            to: testDir.appendingPathComponent("valid.md"),
            atomically: true,
            encoding: .utf8
        )

        try invalidContent.write(
            to: testDir.appendingPathComponent("invalid.md"),
            atomically: true,
            encoding: .utf8
        )

        let engine = RuleEngine(rules: [
            S101_LineLength(),
            F101_TitleRequired(),
            F102_RespondentTypeRequired(),
        ])

        let result = try engine.lint(directory: testDir)

        #expect(!result.isValid)
        #expect(result.fileViolations.count == 1)

        let invalidFile = result.fileViolations.first { $0.file.lastPathComponent == "invalid.md" }
        #expect(invalidFile != nil)
        #expect(invalidFile?.violations.count == 2)

        try cleanupTestDirectory(testDir)
    }

    @Test("Engine respects file filters")
    func engineRespectsFileFilters() throws {
        let testDir = try createTestDirectory()

        let noFrontmatter = "# No frontmatter here"

        try noFrontmatter.write(
            to: testDir.appendingPathComponent("README.md"),
            atomically: true,
            encoding: .utf8
        )

        try noFrontmatter.write(
            to: testDir.appendingPathComponent("CLAUDE.md"),
            atomically: true,
            encoding: .utf8
        )

        let engine = RuleEngine(rules: [
            F101_TitleRequired(),
            F102_RespondentTypeRequired(),
        ])

        let result = try engine.lint(directory: testDir)

        #expect(result.isValid)
        #expect(result.totalViolationCount == 0)

        try cleanupTestDirectory(testDir)
    }

    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }

    func cleanupTestDirectory(_ directory: URL) throws {
        try FileManager.default.removeItem(at: directory)
    }
}
