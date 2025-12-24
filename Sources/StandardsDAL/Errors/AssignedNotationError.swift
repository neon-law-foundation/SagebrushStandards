import Foundation
import Vapor

/// Errors related to assigned notation operations and validation.
public enum AssignedNotationError: Error, LocalizedError {

    /// Notation with specified ID not found.
    case notationNotFound(Int32)

    /// No latest version found for the specified notation.
    case noLatestVersionFound(repository: Int32, code: String)

    /// Attempted to assign an outdated notation version.
    case outdatedVersion(
        requestedNotationID: Int32,
        requestedVersion: String,
        requestedInsertedAt: Date,
        latestNotationID: Int32,
        latestVersion: String,
        latestInsertedAt: Date,
        code: String,
        repositoryID: Int32
    )

    /// Active assignment already exists for this notation and respondents.
    case activeAssignmentExists(notationID: Int32, personID: Int32?, entityID: Int32?)

    public var errorDescription: String? {
        switch self {
        case .notationNotFound(let id):
            return "Notation with ID \(id) not found"
        case .noLatestVersionFound(let repo, let code):
            return "No versions found for notation '\(code)' in repository \(repo)"
        case .outdatedVersion(
            let reqID,
            let reqVer,
            let reqDate,
            let latestID,
            let latestVer,
            let latestDate,
            let code,
            let repoID
        ):
            return """
                Cannot assign outdated notation version.

                Requested: Notation ID \(reqID), version '\(reqVer)', created \(reqDate)
                Latest: Notation ID \(latestID), version '\(latestVer)', created \(latestDate)

                Please use the latest version of '\(code)' from repository \(repoID).
                """
        case .activeAssignmentExists(let notationID, let personID, let entityID):
            return
                "Active assignment already exists for notation \(notationID), person \(personID ?? 0), entity \(entityID ?? 0)"
        }
    }

    public var httpStatus: HTTPStatus {
        switch self {
        case .notationNotFound, .noLatestVersionFound:
            return .notFound
        case .outdatedVersion, .activeAssignmentExists:
            return .conflict
        }
    }
}
