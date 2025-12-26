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

    /// Notation failed validation.
    case validationFailed([NotationValidation])

    /// Invalid frontmatter format or content.
    case invalidFrontmatter(String)

    /// Required field is missing from notation data.
    case missingRequiredField(String)

    public var errorDescription: String? {
        switch self {
        case .versionAlreadyExists(let repo, let code, let version):
            return
                "Notation '\(code)' version '\(version)' already exists in repository \(repo)"
        case .notFound(let repo, let code):
            return "Notation '\(code)' not found in repository \(repo)"
        case .noVersionsFound(let repo, let code):
            return "No versions found for notation '\(code)' in repository \(repo)"
        case .validationFailed(let validations):
            let messages = validations.map { validation in
                var parts = ["[\(validation.violation.ruleCode)]"]
                if let field = validation.field {
                    parts.append("\(field):")
                }
                parts.append(validation.violation.message)
                return parts.joined(separator: " ")
            }
            return "Notation validation failed:\n" + messages.joined(separator: "\n")
        case .invalidFrontmatter(let message):
            return "Invalid frontmatter: \(message)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }

    public var httpStatus: HTTPStatus {
        switch self {
        case .versionAlreadyExists:
            return .conflict
        case .notFound, .noVersionsFound:
            return .notFound
        case .validationFailed, .invalidFrontmatter, .missingRequiredField:
            return .badRequest
        }
    }
}
