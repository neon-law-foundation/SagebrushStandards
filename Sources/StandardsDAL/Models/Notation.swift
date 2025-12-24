import Fluent
import Foundation
import Vapor

/// Defines who can be assigned a notation.
///
/// Notations can target individuals, organizations, or both depending on the requirement.
public enum RespondentType: String, Codable, CaseIterable, Sendable {
    /// Notation assigned to an individual person.
    case person = "person"

    /// Notation assigned to a legal entity or organization.
    case entity = "entity"

    /// Notation assigned to both a person and entity together.
    case personAndEntity = "person_and_entity"
}

/// Represents a notation template (markdown document with frontmatter) that can be assigned to people or entities.
///
/// Notations are versioned templates stored in git repositories. Each notation tracks the git commit SHA
/// it was created from, allowing for audit trails and version control integration.
///
/// ## Topics
///
/// ### Creating Notations
///
/// - ``init()``
/// - ``setDefaultOwner(on:)``
///
/// ### Properties
///
/// - ``id``
/// - ``title``
/// - ``description``
/// - ``respondentType``
/// - ``markdownContent``
/// - ``frontmatter``
/// - ``version``
/// - ``code``
/// - ``gitRepository``
/// - ``owner``
/// - ``insertedAt``
/// - ``updatedAt``
public final class Notation: Model, @unchecked Sendable {
    public static let schema = "notations"

    /// The unique identifier for this notation.
    @ID(custom: .id, generatedBy: .database)
    public var id: Int32?

    /// The display title of the notation.
    @Field(key: "title")
    public var title: String

    /// A brief description of the notation's purpose.
    @Field(key: "description")
    public var description: String

    /// Specifies who this notation can be assigned to.
    ///
    /// See ``RespondentType`` for valid options.
    @Enum(key: "respondent_type")
    public var respondentType: RespondentType

    /// The full markdown content of the notation template.
    @Field(key: "markdown_content")
    public var markdownContent: String

    /// Structured metadata extracted from the notation's frontmatter.
    ///
    /// Stored as JSONB in the database, allowing for flexible key-value pairs.
    @Field(key: "frontmatter")
    public var frontmatter: [String: String]

    /// The git commit SHA from the source repository.
    ///
    /// Tracks which version of the notation template from the git repository this record represents.
    /// This is the commit hash from the main branch of the repository where the notation originated.
    /// Typically a 40-character SHA-1 hash (e.g., "abc123def456789012345678901234567890abcd").
    @Field(key: "version")
    public var version: String

    /// Unique code identifying this notation type within its repository.
    ///
    /// This code remains constant across versions, allowing the system to track different versions
    /// of the same notation. For example, "france-contractor-agreement" would be the code for all
    /// versions of the France contractor agreement notation.
    @OptionalField(key: "code")
    public var code: String?

    /// The Git repository where this notation is stored.
    ///
    /// References the AWS CodeCommit repository containing the notation template.
    @OptionalParent(key: "git_repository_id")
    public var gitRepository: GitRepository?

    /// The entity that owns or manages this notation.
    @OptionalParent(key: "owner_id")
    public var owner: Entity?

    /// The timestamp when this notation was created.
    @Timestamp(key: "inserted_at", on: .create)
    public var insertedAt: Date?

    /// The timestamp when this notation was last updated.
    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    /// Creates a new notation instance.
    public init() {}

    /// Sets the owner to Neon Law Foundation.
    ///
    /// Looks up the Neon Law Foundation entity and assigns it as this notation's owner.
    ///
    /// - Parameter database: The database connection to use for the lookup.
    /// - Throws: `Abort` with `.internalServerError` if Neon Law Foundation entity is not found.
    public func setDefaultOwner(on database: Database) async throws {
        // Find Neon Law Foundation
        let neonLawFoundation = try await Entity.query(on: database)
            .filter(\.$name == "Neon Law Foundation")
            .first()

        guard let neonLawFoundation = neonLawFoundation else {
            throw Abort(.internalServerError, reason: "Neon Law Foundation entity not found")
        }

        self.$owner.id = try neonLawFoundation.requireID()
    }
}
