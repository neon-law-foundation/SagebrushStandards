import Foundation

/// Validates that Markdown files have YAML frontmatter with a title field
public struct FrontmatterValidator {
    public init() {}

    /// Validates all Markdown files in a directory
    public func validate(directory: URL) throws -> FrontmatterValidationResult {
        let fileManager = FileManager.default
        var violations: [FrontmatterFileViolation] = []

        guard
            let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            throw ValidationError.directoryNotAccessible(directory)
        }

        for case let fileURL as URL in enumerator {
            guard FileFilters.shouldValidate(fileURL) else { continue }

            let fileViolations = try validateFile(at: fileURL)
            if !fileViolations.isEmpty {
                violations.append(FrontmatterFileViolation(file: fileURL, violations: fileViolations))
            }
        }

        return FrontmatterValidationResult(violations: violations)
    }

    /// Validates a single Markdown file for frontmatter with title
    public func validateFile(at url: URL) throws -> [FrontmatterViolation] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError.fileNotFound(url)
        }

        let content = try String(contentsOf: url, encoding: .utf8)

        // Check if file has frontmatter
        guard content.hasPrefix("---") else {
            return [FrontmatterViolation(type: .missingFrontmatter)]
        }

        // Extract frontmatter
        let lines = content.components(separatedBy: .newlines)
        guard lines.first == "---" else {
            return [FrontmatterViolation(type: .missingFrontmatter)]
        }

        // Find the closing delimiter
        var frontmatterEndIndex: Int?
        for (index, line) in lines.enumerated() where index > 0 {
            if line == "---" {
                frontmatterEndIndex = index
                break
            }
        }

        guard let endIndex = frontmatterEndIndex else {
            return [FrontmatterViolation(type: .missingFrontmatter)]
        }

        // Extract frontmatter lines (between the --- delimiters)
        let frontmatterLines = Array(lines[1..<endIndex])

        var violations: [FrontmatterViolation] = []

        // Parse frontmatter for title field
        var hasTitle = false
        var titleValue: String?

        for line in frontmatterLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("title:") {
                let value = String(trimmed.dropFirst("title:".count))
                    .trimmingCharacters(in: .whitespaces)
                titleValue = value
                hasTitle = true
                break
            }
        }

        // Check if title exists and is not empty
        if !hasTitle || titleValue?.isEmpty == true {
            violations.append(FrontmatterViolation(type: .missingTitle))
        }

        // Parse frontmatter for respondent_type field
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

        // Check if respondent_type exists and is not empty
        if !hasRespondentType || respondentTypeValue?.isEmpty == true {
            violations.append(FrontmatterViolation(type: .missingRespondentType))
        } else if let respondentType = respondentTypeValue {
            // Validate that respondent_type is one of the allowed values
            let validValues = ["entity", "person", "person_and_entity"]
            if !validValues.contains(respondentType) {
                violations.append(FrontmatterViolation(type: .invalidRespondentType(respondentType)))
            }
        }

        return violations
    }
}

// MARK: - Models

public struct FrontmatterValidationResult {
    public let violations: [FrontmatterFileViolation]

    public var isValid: Bool {
        violations.isEmpty
    }
}

public struct FrontmatterFileViolation {
    public let file: URL
    public let violations: [FrontmatterViolation]
}

public struct FrontmatterViolation {
    public let type: FrontmatterViolationType
}

public enum FrontmatterViolationType: Equatable {
    case missingFrontmatter
    case missingTitle
    case missingRespondentType
    case invalidRespondentType(String)

    public var message: String {
        switch self {
        case .missingFrontmatter:
            return "must have frontmatter"
        case .missingTitle:
            return "must have title"
        case .missingRespondentType:
            return "must have respondent_type (valid values: entity, person, person_and_entity)"
        case .invalidRespondentType(let value):
            return "respondent_type '\(value)' is invalid (valid values: entity, person, person_and_entity)"
        }
    }
}
