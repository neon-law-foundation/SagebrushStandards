import Foundation
import StandardsRules

/// Validates notation data before saving to database
public struct NotationValidator {
    public init() {}

    /// Validate notation fields
    ///
    /// - Parameters:
    ///   - title: The notation title
    ///   - description: The notation description
    ///   - respondentType: The respondent type value
    ///   - frontmatter: The full frontmatter dictionary
    ///   - markdownContent: The markdown content
    /// - Returns: Array of validation failures (empty if valid)
    public func validate(
        title: String,
        description: String,
        respondentType: String,
        frontmatter: [String: String],
        markdownContent: String
    ) -> [NotationValidation] {
        var validations: [NotationValidation] = []

        validations.append(contentsOf: validateTitle(title))
        validations.append(contentsOf: validateRespondentType(respondentType))

        return validations
    }

    /// Validate that title is non-empty (mirrors F101 rule)
    private func validateTitle(_ title: String) -> [NotationValidation] {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            return [
                NotationValidation(
                    violation: Violation(
                        ruleCode: "F101",
                        message: "Title must not be empty"
                    ),
                    field: "title"
                )
            ]
        }
        return []
    }

    /// Validate that respondent_type is valid (mirrors F102 rule)
    private func validateRespondentType(_ respondentType: String) -> [NotationValidation] {
        let validRespondentTypes = ["entity", "person", "person_and_entity"]

        if !validRespondentTypes.contains(respondentType) {
            return [
                NotationValidation(
                    violation: Violation(
                        ruleCode: "F102",
                        message: "Invalid respondent_type: '\(respondentType)'",
                        context: [
                            "value": respondentType,
                            "valid_values": validRespondentTypes.joined(separator: ", "),
                        ]
                    ),
                    field: "respondent_type"
                )
            ]
        }
        return []
    }
}
