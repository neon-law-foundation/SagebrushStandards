import Foundation

/// F101: Frontmatter must contain a non-empty title field
public struct F101_TitleRequired: Rule {
    public let code = "F101"
    public let description = "Frontmatter must contain a non-empty title field"

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
                    message: "Missing frontmatter with title field"
                )
            ]
        }

        let lines = content.components(separatedBy: .newlines)
        guard lines.first == "---" else {
            return [
                Violation(
                    ruleCode: code,
                    message: "Missing frontmatter with title field"
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
                    message: "Missing frontmatter with title field"
                )
            ]
        }

        let frontmatterLines = Array(lines[1..<endIndex])

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

        if !hasTitle || titleValue?.isEmpty == true {
            return [
                Violation(
                    ruleCode: code,
                    message: "Frontmatter must contain a non-empty title field"
                )
            ]
        }

        return []
    }
}
