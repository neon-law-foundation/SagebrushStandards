import Foundation
import Testing

@testable import StandardsCLI

@Suite("Frontmatter Validator")
struct FrontmatterValidatorTests {
    let validator = FrontmatterValidator()

    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrontmatterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanupTestDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Valid file with title in frontmatter passes validation")
    func validFileWithTitleInFrontmatter() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("valid.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: person
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.isEmpty)
    }

    @Test("Valid file with title and other fields passes validation")
    func validFileWithTitleAndOtherFields() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("valid.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: entity
            author: John Doe
            date: 2025-12-20
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.isEmpty)
    }

    @Test("File without frontmatter fails validation")
    func fileWithoutFrontmatterFailsValidation() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("no-frontmatter.md")
        let content = """
            # Content here

            This file has no frontmatter at all.
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 1)
        #expect(violations[0].type == .missingFrontmatter)
    }

    @Test("File with empty frontmatter fails validation")
    func fileWithEmptyFrontmatterFailsValidation() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("empty-frontmatter.md")
        let content = """
            ---
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 2)
        #expect(violations.contains { $0.type == .missingTitle })
        #expect(violations.contains { $0.type == .missingRespondentType })
    }

    @Test("File with frontmatter but no title field fails validation")
    func fileWithFrontmatterButNoTitleFailsValidation() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("no-title.md")
        let content = """
            ---
            author: John Doe
            date: 2025-12-20
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 2)
        #expect(violations.contains { $0.type == .missingTitle })
        #expect(violations.contains { $0.type == .missingRespondentType })
    }

    @Test("File with empty title value fails validation")
    func fileWithEmptyTitleValueFailsValidation() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("empty-title.md")
        let content = """
            ---
            title:
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 2)
        #expect(violations.contains { $0.type == .missingTitle })
        #expect(violations.contains { $0.type == .missingRespondentType })
    }

    @Test("File with whitespace-only title fails validation")
    func fileWithWhitespaceOnlyTitleFailsValidation() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("whitespace-title.md")
        let content = """
            ---
            title:
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 2)
        #expect(violations.contains { $0.type == .missingTitle })
        #expect(violations.contains { $0.type == .missingRespondentType })
    }

    @Test("README.md files are excluded from frontmatter validation")
    func readmeFilesAreExcluded() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let readmeURL = testDir.appendingPathComponent("README.md")
        let content = """
            # README

            This file has no frontmatter but should be excluded.
            """
        try content.write(to: readmeURL, atomically: true, encoding: .utf8)

        let result = try validator.validate(directory: testDir)
        #expect(result.isValid)
        #expect(result.violations.isEmpty)
    }

    @Test("Directory validation finds all files without title")
    func directoryValidationFindsAllFilesWithoutTitle() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create nested directory structure
        let subdir = testDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        // Valid file in root
        let validFile = testDir.appendingPathComponent("valid.md")
        try """
        ---
        title: Valid Document
        respondent_type: person
        ---

        # Content
        """.write(to: validFile, atomically: true, encoding: .utf8)

        // Invalid file in root (no frontmatter)
        let invalidFile1 = testDir.appendingPathComponent("invalid1.md")
        try "# No frontmatter".write(to: invalidFile1, atomically: true, encoding: .utf8)

        // Invalid file in subdirectory (frontmatter but no title)
        let invalidFile2 = subdir.appendingPathComponent("invalid2.md")
        try """
        ---
        author: Someone
        ---

        # Content
        """.write(to: invalidFile2, atomically: true, encoding: .utf8)

        // README.md file (should be excluded)
        let readmeFile = testDir.appendingPathComponent("README.md")
        try "# README with no frontmatter".write(to: readmeFile, atomically: true, encoding: .utf8)

        let result = try validator.validate(directory: testDir)
        #expect(!result.isValid)
        #expect(result.violations.count == 2)
    }

    @Test("Directory with only valid files passes validation")
    func directoryWithOnlyValidFilesPassesValidation() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let file1 = testDir.appendingPathComponent("file1.md")
        let file2 = testDir.appendingPathComponent("file2.md")

        try """
        ---
        title: Document 1
        respondent_type: entity
        ---

        # Content 1
        """.write(to: file1, atomically: true, encoding: .utf8)

        try """
        ---
        title: Document 2
        respondent_type: person
        ---

        # Content 2
        """.write(to: file2, atomically: true, encoding: .utf8)

        let result = try validator.validate(directory: testDir)
        #expect(result.isValid)
        #expect(result.violations.isEmpty)
    }

    @Test("Validation throws error for non-existent file")
    func validationThrowsErrorForNonExistentFile() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let nonExistentURL = testDir.appendingPathComponent("does-not-exist.md")

        #expect(throws: ValidationError.self) {
            try validator.validateFile(at: nonExistentURL)
        }
    }

    @Test("Valid file with title and respondent_type 'entity' passes validation")
    func validFileWithTitleAndRespondentTypeEntity() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("valid.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: entity
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.isEmpty)
    }

    @Test("Valid file with title and respondent_type 'person' passes validation")
    func validFileWithTitleAndRespondentTypePerson() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("valid.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: person
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.isEmpty)
    }

    @Test("Valid file with title and respondent_type 'person_and_entity' passes validation")
    func validFileWithTitleAndRespondentTypePersonAndEntity() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("valid.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: person_and_entity
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.isEmpty)
    }

    @Test("File with title but missing respondent_type fails validation")
    func fileWithTitleButMissingRespondentTypeFails() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("no-respondent-type.md")
        let content = """
            ---
            title: My Document Title
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 1)
        #expect(violations[0].type == .missingRespondentType)
    }

    @Test("File with empty respondent_type fails validation")
    func fileWithEmptyRespondentTypeFails() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("empty-respondent-type.md")
        let content = """
            ---
            title: My Document Title
            respondent_type:
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 1)
        #expect(violations[0].type == .missingRespondentType)
    }

    @Test("File with invalid respondent_type 'company' fails validation")
    func fileWithInvalidRespondentTypeCompany() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("invalid-respondent-type.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: company
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 1)
        #expect(violations[0].type == .invalidRespondentType("company"))
    }

    @Test("File with invalid respondent_type 'organization' fails validation")
    func fileWithInvalidRespondentTypeOrganization() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("invalid-respondent-type.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: organization
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 1)
        #expect(violations[0].type == .invalidRespondentType("organization"))
    }

    @Test("File with missing title and missing respondent_type reports both violations")
    func fileWithMissingTitleAndMissingRespondentType() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("missing-both.md")
        let content = """
            ---
            author: John Doe
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 2)
        #expect(violations.contains { $0.type == .missingTitle })
        #expect(violations.contains { $0.type == .missingRespondentType })
    }

    @Test("File with missing title and invalid respondent_type reports both violations")
    func fileWithMissingTitleAndInvalidRespondentType() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("missing-title-invalid-type.md")
        let content = """
            ---
            author: John Doe
            respondent_type: invalid_value
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try validator.validateFile(at: fileURL)
        #expect(violations.count == 2)
        #expect(violations.contains { $0.type == .missingTitle })
        #expect(violations.contains { $0.type == .invalidRespondentType("invalid_value") })
    }
}
