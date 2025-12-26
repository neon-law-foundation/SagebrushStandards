import Foundation
import StandardsRules

/// Represents a validation failure for a Notation model
public struct NotationValidation: Sendable {
    /// The underlying rule violation
    public let violation: Violation

    /// The specific field that failed validation (if applicable)
    public let field: String?

    public init(violation: Violation, field: String? = nil) {
        self.violation = violation
        self.field = field
    }
}
