import Foundation
import Logging
import StandardsDAL
import StandardsRules

/// Imports markdown notation files into the database
public struct NotationImporter {
    private let notationService: NotationService
    private let logger: Logger
    private let parser = FrontmatterParser()

    public init(notationService: NotationService, logger: Logger) {
        self.notationService = notationService
        self.logger = logger
    }

    /// Import a markdown file as a notation
    ///
    /// - Parameters:
    ///   - fileURL: The markdown file to import
    ///   - gitRepositoryID: The git repository ID
    ///   - version: The git commit SHA
    /// - Returns: The created notation
    /// - Throws: NotationError if validation fails or required fields are missing
    public func importMarkdownFile(
        _ fileURL: URL,
        gitRepositoryID: Int32,
        version: String
    ) async throws -> Notation {
        logger.info("Importing notation from \(fileURL.path)")

        let content = try String(contentsOf: fileURL, encoding: .utf8)

        guard let (frontmatter, markdownContent) = parser.parse(content) else {
            throw NotationError.invalidFrontmatter("File must have valid YAML frontmatter")
        }

        guard let title = frontmatter["title"], !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NotationError.missingRequiredField("title")
        }

        guard let description = frontmatter["description"], !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NotationError.missingRequiredField("description")
        }

        guard let respondentTypeRaw = frontmatter["respondent_type"],
            let respondentType = RespondentType(rawValue: respondentTypeRaw)
        else {
            throw NotationError.missingRequiredField("respondent_type")
        }

        let code = fileURL.deletingPathExtension().lastPathComponent

        logger.debug("Creating notation with code: \(code), title: \(title)")

        let notation = try await notationService.createVersionWithValidation(
            gitRepositoryID: gitRepositoryID,
            code: code,
            version: version,
            title: title,
            description: description,
            respondentType: respondentType,
            markdownContent: markdownContent,
            frontmatter: frontmatter,
            ownerID: nil
        )

        logger.info("Successfully imported notation: \(code) - \(title)")

        return notation
    }
}
