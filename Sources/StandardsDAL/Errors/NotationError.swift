import Foundation
import Vapor

/// Errors related to notation operations and version management.
public enum NotationError: Error, LocalizedError {

    /// Attempted to create a notation version that already exists.
    case versionAlreadyExists(repository: Int32, code: String, version: String)

    /// Notation with specified repository and code not found.
    case notFound(repository: Int32, code: String)

    /// No versions found for the specified notation.
    case noVersionsFound(repository: Int32, code: String)

    public var errorDescription: String? {
        switch self {
        case .versionAlreadyExists(let repo, let code, let version):
            return
                "Notation '\(code)' version '\(version)' already exists in repository \(repo)"
        case .notFound(let repo, let code):
            return "Notation '\(code)' not found in repository \(repo)"
        case .noVersionsFound(let repo, let code):
            return "No versions found for notation '\(code)' in repository \(repo)"
        }
    }

    public var httpStatus: HTTPStatus {
        switch self {
        case .versionAlreadyExists:
            return .conflict
        case .notFound, .noVersionsFound:
            return .notFound
        }
    }
}
