import Foundation
import Testing

@testable import StandardsCLI

@Suite("F102: Respondent Type Required")
struct F102_RespondentTypeRequiredTests {
    let rule = F102_RespondentTypeRequired()

    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "F102Tests-\(UUID().uuidString)"
        )
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanupTestDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Valid file with respondent_type 'entity' has no F102 violations")
    func validFileWithRespondentTypeEntity() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("valid.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: entity
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.isEmpty)

        cleanupTestDirectory(testDir)
    }

    @Test("Valid file with respondent_type 'person' has no F102 violations")
    func validFileWithRespondentTypePerson() throws {
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

    @Test("Valid file with respondent_type 'person_and_entity' has no F102 violations")
    func validFileWithRespondentTypePersonAndEntity() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("valid.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: person_and_entity
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.isEmpty)

        cleanupTestDirectory(testDir)
    }

    @Test("File without frontmatter generates F102 violation")
    func fileWithoutFrontmatterGeneratesF102Violation() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("no-frontmatter.md")
        let content = """
            # Content here

            This file has no frontmatter at all.
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F102")
        #expect(
            violations[0].message == "Missing frontmatter with respondent_type field"
        )

        cleanupTestDirectory(testDir)
    }

    @Test("File with frontmatter but no respondent_type generates F102 violation")
    func fileWithFrontmatterButNoRespondentTypeGeneratesF102Violation() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("no-respondent-type.md")
        let content = """
            ---
            title: My Document Title
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F102")
        #expect(
            violations[0].message
                == "Frontmatter must contain a non-empty respondent_type field"
        )

        cleanupTestDirectory(testDir)
    }

    @Test("File with empty respondent_type generates F102 violation")
    func fileWithEmptyRespondentTypeGeneratesF102Violation() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("empty-respondent-type.md")
        let content = """
            ---
            title: My Document Title
            respondent_type:
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F102")
        #expect(
            violations[0].message
                == "Frontmatter must contain a non-empty respondent_type field"
        )

        cleanupTestDirectory(testDir)
    }

    @Test("File with invalid respondent_type 'company' generates F102 violation")
    func fileWithInvalidRespondentTypeCompany() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("invalid-respondent-type.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: company
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F102")
        #expect(violations[0].message == "Invalid respondent_type value: 'company'")
        #expect(
            violations[0].context?["value"] == "company"
        )
        #expect(
            violations[0].context?["valid_values"] == "entity, person, person_and_entity"
        )

        cleanupTestDirectory(testDir)
    }

    @Test("File with invalid respondent_type 'organization' generates F102 violation")
    func fileWithInvalidRespondentTypeOrganization() throws {
        let testDir = try createTestDirectory()

        let fileURL = testDir.appendingPathComponent("invalid-respondent-type.md")
        let content = """
            ---
            title: My Document Title
            respondent_type: organization
            ---

            # Content here
            """
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let violations = try rule.validate(file: fileURL)

        #expect(violations.count == 1)
        #expect(violations[0].ruleCode == "F102")
        #expect(
            violations[0].message == "Invalid respondent_type value: 'organization'"
        )
        #expect(violations[0].context?["value"] == "organization")

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
