import Fluent
import Foundation
import Vapor

/// Represents the lifecycle state of an assigned notation.
///
/// An assigned notation moves through various states from initial assignment to completion.
/// The state machine ensures proper workflow orchestration and prevents duplicate active assignments.
///
/// ## State Transitions
///
/// ```
/// open → review → closed
///   ↓       ↓
///   ↓   waiting_for_alignment → review/closed
///   ↓
/// waiting_for_flow → open/closed
/// ```
///
/// ## Topics
///
/// ### States
///
/// - ``open``
/// - ``review``
/// - ``waitingForFlow``
/// - ``waitingForAlignment``
/// - ``closed``
public enum AssignedNotationState: String, Codable, CaseIterable, Sendable {

    /// The initial state when a notation is first assigned to a respondent.
    ///
    /// In this state, the respondent needs to complete the notation requirements.
    /// The assignment remains active and prevents duplicate assignments for the same notation and respondent.
    ///
    /// ### Valid Transitions
    /// - ``review``: When the respondent submits their response
    /// - ``waitingForFlow``: When a dependency on another flow is detected
    /// - ``waitingForAlignment``: When alignment with related entities or people is required
    /// - ``closed``: When auto-completion rules are met
    case open = "open"

    /// The state when a submitted response is awaiting review.
    ///
    /// A reviewer examines the respondent's submission to determine if it meets requirements.
    /// The assignment is considered active during review.
    ///
    /// ### Valid Transitions
    /// - ``open``: When the reviewer requests changes from the respondent
    /// - ``waitingForAlignment``: When the reviewer identifies alignment needs
    /// - ``closed``: When the reviewer approves the response
    case review = "review"

    /// The state when waiting for a dependent flow or process to complete.
    ///
    /// The notation is blocked because it depends on another workflow to finish first.
    /// The assignment remains active but no action can be taken until the dependency resolves.
    ///
    /// ### Valid Transitions
    /// - ``open``: When the blocking flow completes and further action is needed
    /// - ``closed``: When the blocking flow completes and auto-approval rules are met
    case waitingForFlow = "waiting_for_flow"

    /// The state when waiting for alignment or coordination with other parties.
    ///
    /// The notation requires input, agreement, or coordination from related people or entities
    /// before proceeding. The assignment remains active during alignment.
    ///
    /// ### Valid Transitions
    /// - ``open``: When alignment completes and the respondent needs to update their response
    /// - ``review``: When alignment completes and the response needs review
    /// - ``closed``: When alignment completes and auto-approval rules are met
    case waitingForAlignment = "waiting_for_alignment"

    /// The final state when the notation assignment is completed and finalized.
    ///
    /// The assignment is no longer active. This allows new assignments of the same notation
    /// to the same respondent if needed. Closed assignments are archived and cannot be reopened.
    case closed = "closed"
}

/// Represents a notation assigned to a person, entity, or both.
///
/// An `AssignedNotation` links a ``Notation`` template to specific respondents (people, entities, or both)
/// and tracks the assignment through its lifecycle using a state machine.
///
/// The assignment enforces business rules based on the notation's respondent type:
/// - For `.person` notations, only `person_id` must be set
/// - For `.entity` notations, only `entity_id` must be set
/// - For `.personAndEntity` notations, both IDs must be set
///
/// Database constraints prevent duplicate active assignments to ensure only one assignment
/// can be in an active state (not `closed`) for a given notation and respondent combination.
///
/// ## Topics
///
/// ### Creating and Validating Assignments
///
/// - ``init()``
/// - ``validate(on:)``
///
/// ### Checking Assignment Status
///
/// - ``hasActiveAssignment(notationID:personID:entityID:on:)``
///
/// ### Properties
///
/// - ``id``
/// - ``notation``
/// - ``person``
/// - ``entity``
/// - ``state``
/// - ``insertedAt``
/// - ``updatedAt``
public final class AssignedNotation: Model, @unchecked Sendable {
    public static let schema = "assigned_notations"

    /// The unique identifier for this assignment.
    @ID(custom: .id, generatedBy: .database)
    public var id: Int32?

    /// The notation template that this assignment references.
    @Parent(key: "notation_id")
    public var notation: Notation

    /// The person assigned to this notation, if applicable.
    ///
    /// Required when the notation's respondent type is `.person` or `.personAndEntity`.
    /// Must be `nil` when the respondent type is `.entity`.
    @OptionalParent(key: "person_id")
    public var person: Person?

    /// The entity assigned to this notation, if applicable.
    ///
    /// Required when the notation's respondent type is `.entity` or `.personAndEntity`.
    /// Must be `nil` when the respondent type is `.person`.
    @OptionalParent(key: "entity_id")
    public var entity: Entity?

    /// The current state of this assignment in its lifecycle.
    ///
    /// See ``AssignedNotationState`` for valid states and transitions.
    @Enum(key: "state")
    public var state: AssignedNotationState

    /// The timestamp when this assignment was created.
    @Timestamp(key: "inserted_at", on: .create)
    public var insertedAt: Date?

    /// The timestamp when this assignment was last updated.
    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    /// Creates a new assigned notation instance.
    public init() {}

    /// Validates that the assignment has the correct person and entity IDs based on the notation's respondent type.
    ///
    /// This method enforces business rules by checking that the assignment's person and entity IDs
    /// match the requirements of the notation's respondent type:
    /// - `.person` requires `person_id` set and `entity_id` nil
    /// - `.entity` requires `entity_id` set and `person_id` nil
    /// - `.personAndEntity` requires both IDs set
    ///
    /// Call this method before saving a new assignment to ensure data integrity.
    ///
    /// - Parameter database: The database connection to use for loading the notation.
    /// - Throws: `Abort` with `.badRequest` status if the IDs don't match the respondent type requirements.
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

    /// Checks if an active assignment already exists for the same notation and respondent combination.
    ///
    /// An assignment is considered active if its state is `.open`. This method queries the database
    /// to determine if an existing active assignment prevents creating a new one for the same
    /// notation and respondent (person, entity, or both).
    ///
    /// Use this method before creating a new assignment to provide better error messages than
    /// relying on database constraint violations.
    ///
    /// - Parameters:
    ///   - notationID: The ID of the notation to check.
    ///   - personID: The person ID to check, or `nil` if not applicable.
    ///   - entityID: The entity ID to check, or `nil` if not applicable.
    ///   - database: The database connection to use for the query.
    /// - Returns: `true` if an active assignment exists, `false` otherwise.
    /// - Throws: Database errors that occur during the query.
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
