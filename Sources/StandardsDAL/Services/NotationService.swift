import Fluent
import Foundation
import Vapor

/// Service responsible for notation version management and validation.
public actor NotationService {
    private let database: Database
    private let validator = NotationValidator()

    public init(database: Database) {
        self.database = database
    }

    /// Finds the latest version of a notation by repository and code.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: The notation code.
    /// - Returns: The most recent notation, or nil if none exists.
    public func findLatestVersion(
        gitRepositoryID: Int32,
        code: String
    ) async throws -> Notation? {
        let results = try await Notation.query(on: database)
            .filter(\.$gitRepository.$id == gitRepositoryID)
            .sort(\.$insertedAt, .descending)
            .all()

        return results.first { $0.code == code }
    }

    /// Finds all versions of a notation ordered by most recent first.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: The notation code.
    /// - Returns: An array of all versions of the notation.
    public func findAllVersions(
        gitRepositoryID: Int32,
        code: String
    ) async throws -> [Notation] {
        let results = try await Notation.query(on: database)
            .filter(\.$gitRepository.$id == gitRepositoryID)
            .sort(\.$insertedAt, .descending)
            .all()

        return results.filter { $0.code == code }
    }

    /// Creates a new notation version.
    ///
    /// Validates that this creates a newer version than existing ones.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: Unique code for this notation type.
    ///   - version: Git commit SHA.
    ///   - title: Display title.
    ///   - description: Brief description.
    ///   - respondentType: Who can be assigned this notation.
    ///   - markdownContent: The notation template content.
    ///   - frontmatter: Structured metadata.
    ///   - ownerID: Optional owner entity ID.
    /// - Returns: The created notation.
    /// - Throws: `NotationError` if version already exists.
    public func createVersion(
        gitRepositoryID: Int32,
        code: String,
        version: String,
        title: String,
        description: String,
        respondentType: RespondentType,
        markdownContent: String,
        frontmatter: [String: String],
        ownerID: Int32?
    ) async throws -> Notation {
        let allVersions = try await Notation.query(on: database)
            .filter(\.$gitRepository.$id == gitRepositoryID)
            .filter(\.$version == version)
            .all()

        if allVersions.contains(where: { $0.code == code }) {
            throw NotationError.versionAlreadyExists(
                repository: gitRepositoryID,
                code: code,
                version: version
            )
        }

        let notation = Notation()
        notation.$gitRepository.id = gitRepositoryID
        notation.code = code
        notation.version = version
        notation.title = title
        notation.description = description
        notation.respondentType = respondentType
        notation.markdownContent = markdownContent
        notation.frontmatter = frontmatter
        notation.$owner.id = ownerID

        try await notation.save(on: database)
        return notation
    }

    /// Creates a new notation version with validation.
    ///
    /// Validates all notation fields before saving to the database.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: Unique code for this notation type.
    ///   - version: Git commit SHA.
    ///   - title: Display title.
    ///   - description: Brief description.
    ///   - respondentType: Who can be assigned this notation.
    ///   - markdownContent: The notation template content.
    ///   - frontmatter: Structured metadata.
    ///   - ownerID: Optional owner entity ID.
    /// - Returns: The created notation.
    /// - Throws: `NotationError.validationFailed` if validation fails, or other `NotationError` types.
    public func createVersionWithValidation(
        gitRepositoryID: Int32,
        code: String,
        version: String,
        title: String,
        description: String,
        respondentType: RespondentType,
        markdownContent: String,
        frontmatter: [String: String],
        ownerID: Int32?
    ) async throws -> Notation {
        let validations = validator.validate(
            title: title,
            description: description,
            respondentType: respondentType.rawValue,
            frontmatter: frontmatter,
            markdownContent: markdownContent
        )

        if !validations.isEmpty {
            throw NotationError.validationFailed(validations)
        }

        return try await createVersion(
            gitRepositoryID: gitRepositoryID,
            code: code,
            version: version,
            title: title,
            description: description,
            respondentType: respondentType,
            markdownContent: markdownContent,
            frontmatter: frontmatter,
            ownerID: ownerID
        )
    }
}
