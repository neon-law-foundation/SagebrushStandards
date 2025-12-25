import Foundation

/// F102: Frontmatter must contain a valid respondent_type field
public struct F102_RespondentTypeRequired: Rule {
    public let code = "F102"
    public let description =
        "Frontmatter must contain a valid respondent_type field (entity, person, or person_and_entity)"

    private let validValues = ["entity", "person", "person_and_entity"]

    public init() {}

    public func validate(file: URL) throws -> [Violation] {
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw ValidationError.fileNotFound(file)
        }

        let content = try String(contentsOf: file, encoding: .utf8)

        guard content.hasPrefix("---") else {
            return [
                Violation(
                    ruleCode: code,
                    message: "Missing frontmatter with respondent_type field"
                )
            ]
        }

        let lines = content.components(separatedBy: .newlines)
        guard lines.first == "---" else {
            return [
                Violation(
                    ruleCode: code,
                    message: "Missing frontmatter with respondent_type field"
                )
            ]
        }

        var frontmatterEndIndex: Int?
        for (index, line) in lines.enumerated() where index > 0 {
            if line == "---" {
                frontmatterEndIndex = index
                break
            }
        }

        guard let endIndex = frontmatterEndIndex else {
            return [
                Violation(
                    ruleCode: code,
                    message: "Missing frontmatter with respondent_type field"
                )
            ]
        }

        let frontmatterLines = Array(lines[1..<endIndex])

        var hasRespondentType = false
        var respondentTypeValue: String?

        for line in frontmatterLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("respondent_type:") {
                let value = String(trimmed.dropFirst("respondent_type:".count))
                    .trimmingCharacters(in: .whitespaces)
                respondentTypeValue = value
                hasRespondentType = true
                break
            }
        }

        if !hasRespondentType || respondentTypeValue?.isEmpty == true {
            return [
                Violation(
                    ruleCode: code,
                    message: "Frontmatter must contain a non-empty respondent_type field",
                    context: ["valid_values": validValues.joined(separator: ", ")]
                )
            ]
        }

        if let respondentType = respondentTypeValue {
            if !validValues.contains(respondentType) {
                return [
                    Violation(
                        ruleCode: code,
                        message: "Invalid respondent_type value: '\(respondentType)'",
                        context: [
                            "value": respondentType,
                            "valid_values": validValues.joined(separator: ", "),
                        ]
                    )
                ]
            }
        }

        return []
    }
}
