import Fluent
import Foundation
import Vapor

// Enum for respondent types
public enum RespondentType: String, Codable, CaseIterable, Sendable {
    case person = "person"
    case entity = "entity"
    case personAndEntity = "person_and_entity"
}

// Represents a notation (markdown document with frontmatter) that can be assigned to people or entities
public final class Notation: Model, @unchecked Sendable {
    public static let schema = "notations"

    @ID(custom: .id, generatedBy: .database)
    public var id: Int32?

    @Field(key: "title")
    public var title: String

    @Field(key: "description")
    public var description: String

    @Enum(key: "respondent_type")
    public var respondentType: RespondentType

    @Field(key: "markdown_content")
    public var markdownContent: String

    // Frontmatter stored as JSONB - can be any valid JSON structure
    @Field(key: "frontmatter")
    public var frontmatter: [String: String]

    @OptionalParent(key: "owner_id")
    public var owner: Entity?

    @Timestamp(key: "inserted_at", on: .create)
    public var insertedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() {}

    /// Sets the owner to Neon Law Foundation
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
