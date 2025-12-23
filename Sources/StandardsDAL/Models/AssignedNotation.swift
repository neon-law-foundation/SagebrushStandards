import Fluent
import Foundation
import Vapor

// Enum for assigned notation states
public enum AssignedNotationState: String, Codable, CaseIterable, Sendable {
    case open = "open"
    case closed = "closed"
}

// Represents a notation assigned to a person, entity, or both
public final class AssignedNotation: Model, @unchecked Sendable {
    public static let schema = "assigned_notations"

    @ID(custom: .id, generatedBy: .database)
    public var id: Int32?

    @Parent(key: "notation_id")
    public var notation: Notation

    @OptionalParent(key: "person_id")
    public var person: Person?

    @OptionalParent(key: "entity_id")
    public var entity: Entity?

    @Enum(key: "state")
    public var state: AssignedNotationState

    @Timestamp(key: "inserted_at", on: .create)
    public var insertedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() {}

    /// Validates that the assigned notation has the correct person/entity IDs based on the notation's respondent type
    public func validate(on database: Database) async throws {
        // Load the notation to check respondent type
        try await self.$notation.load(on: database)

        let personID = self.$person.id
        let entityID = self.$entity.id

        switch self.notation.respondentType {
        case .person:
            guard personID != nil && entityID == nil else {
                throw Abort(
                    .badRequest,
                    reason:
                        "For respondent type 'person', person_id must be set and entity_id must be nil"
                )
            }
        case .entity:
            guard entityID != nil && personID == nil else {
                throw Abort(
                    .badRequest,
                    reason:
                        "For respondent type 'entity', entity_id must be set and person_id must be nil"
                )
            }
        case .personAndEntity:
            guard personID != nil && entityID != nil else {
                throw Abort(
                    .badRequest,
                    reason:
                        "For respondent type 'person_and_entity', both person_id and entity_id must be set"
                )
            }
        }
    }

    /// Checks if an active (open) assignment already exists for the same notation and person/entity combination
    public static func hasActiveAssignment(
        notationID: Int32,
        personID: Int32?,
        entityID: Int32?,
        on database: Database
    ) async throws -> Bool {
        var query = AssignedNotation.query(on: database)
            .filter(\.$notation.$id == notationID)
            .filter(\.$state == .open)

        if let personID = personID {
            query = query.filter(\.$person.$id == personID)
        } else {
            query = query.filter(\.$person.$id == nil)
        }

        if let entityID = entityID {
            query = query.filter(\.$entity.$id == entityID)
        } else {
            query = query.filter(\.$entity.$id == nil)
        }

        let count = try await query.count()
        return count > 0
    }
}
