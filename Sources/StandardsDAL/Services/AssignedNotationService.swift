import Fluent
import Foundation
import Vapor

/// Service responsible for creating and managing assigned notations with version validation.
public actor AssignedNotationService {
    private let database: Database
    private let notationService: NotationService

    public init(database: Database) {
        self.database = database
        self.notationService = NotationService(database: database)
    }

    /// Creates a new assignment after validating it uses the latest notation version.
    ///
    /// This method enforces the business rule that assignments can only be created from
    /// the latest version of a notation. If a newer version exists, the assignment is rejected.
    ///
    /// - Parameters:
    ///   - notationID: The notation to assign.
    ///   - personID: The person to assign to (if applicable).
    ///   - entityID: The entity to assign to (if applicable).
    ///   - state: The initial state for the assignment (defaults to `.open`).
    /// - Returns: The created AssignedNotation.
    /// - Throws: `AssignedNotationError` if validation fails.
    public func createAssignment(
        notationID: Int32,
        personID: Int32?,
        entityID: Int32?,
        state: AssignedNotationState = .open
    ) async throws -> AssignedNotation {

        guard let notation = try await Notation.find(notationID, on: database) else {
            throw AssignedNotationError.notationNotFound(notationID)
        }

        try await notation.$gitRepository.load(on: database)

        guard let gitRepo = notation.gitRepository else {
            throw AssignedNotationError.notationNotFound(notationID)
        }
        let gitRepoID = try gitRepo.requireID()

        guard let code = notation.code else {
            throw AssignedNotationError.notationNotFound(notationID)
        }

        guard
            let latestVersion = try await notationService.findLatestVersion(
                gitRepositoryID: gitRepoID,
                code: code
            )
        else {
            throw AssignedNotationError.noLatestVersionFound(
                repository: gitRepoID,
                code: code
            )
        }

        let latestNotationID = try latestVersion.requireID()
        if latestNotationID != notationID {
            throw AssignedNotationError.outdatedVersion(
                requestedNotationID: notationID,
                requestedVersion: notation.version,
                requestedInsertedAt: notation.insertedAt!,
                latestNotationID: latestNotationID,
                latestVersion: latestVersion.version,
                latestInsertedAt: latestVersion.insertedAt!,
                code: code,
                repositoryID: gitRepoID
            )
        }

        let hasActive = try await AssignedNotation.hasActiveAssignment(
            notationID: notationID,
            personID: personID,
            entityID: entityID,
            on: database
        )

        if hasActive {
            throw AssignedNotationError.activeAssignmentExists(
                notationID: notationID,
                personID: personID,
                entityID: entityID
            )
        }

        let assignment = AssignedNotation()
        assignment.$notation.id = notationID
        assignment.$person.id = personID
        assignment.$entity.id = entityID
        assignment.state = state

        try await assignment.validate(on: database)

        try await assignment.save(on: database)

        return assignment
    }

    /// Creates assignment using repository and code, automatically using the latest version.
    ///
    /// This is a convenience method that finds the latest version of a notation by its
    /// repository and code, then creates an assignment to it.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: The notation code.
    ///   - personID: The person to assign to (if applicable).
    ///   - entityID: The entity to assign to (if applicable).
    ///   - state: The initial state for the assignment (defaults to `.open`).
    /// - Returns: The created AssignedNotation.
    /// - Throws: `AssignedNotationError` if no latest version is found or validation fails.
    public func createAssignmentByCode(
        gitRepositoryID: Int32,
        code: String,
        personID: Int32?,
        entityID: Int32?,
        state: AssignedNotationState = .open
    ) async throws -> AssignedNotation {
        guard
            let latestNotation = try await notationService.findLatestVersion(
                gitRepositoryID: gitRepositoryID,
                code: code
            )
        else {
            throw AssignedNotationError.noLatestVersionFound(
                repository: gitRepositoryID,
                code: code
            )
        }

        return try await createAssignment(
            notationID: try latestNotation.requireID(),
            personID: personID,
            entityID: entityID,
            state: state
        )
    }
}
