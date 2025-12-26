import Foundation

/// Utility for parsing YAML frontmatter from markdown files
public struct FrontmatterParser {
    public init() {}

    /// Parse frontmatter from file content
    /// Returns a dictionary of frontmatter key-value pairs and the remaining markdown content
    public func parse(_ content: String) -> (frontmatter: [String: String], markdown: String)? {
        guard content.hasPrefix("---") else {
            return nil
        }

        let lines = content.components(separatedBy: .newlines)
        guard lines.first == "---" else {
            return nil
        }

        var frontmatterEndIndex: Int?
        for (index, line) in lines.enumerated() where index > 0 {
            if line == "---" {
                frontmatterEndIndex = index
                break
            }
        }

        guard let endIndex = frontmatterEndIndex else {
            return nil
        }

        let frontmatterLines = Array(lines[1..<endIndex])
        var frontmatter: [String: String] = [:]

        for line in frontmatterLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard !trimmed.isEmpty else { continue }

            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[trimmed.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespaces)
                frontmatter[key] = value
            }
        }

        let markdownStartIndex = endIndex + 1
        let markdownLines = Array(lines[markdownStartIndex...])
        let markdown = markdownLines.joined(separator: "\n")

        return (frontmatter, markdown)
    }

    /// Check if file has frontmatter
    public func hasFrontmatter(_ content: String) -> Bool {
        guard content.hasPrefix("---") else {
            return false
        }

        let lines = content.components(separatedBy: .newlines)
        guard lines.first == "---" else {
            return false
        }

        for (index, line) in lines.enumerated() where index > 0 {
            if line == "---" {
                return true
            }
        }

        return false
    }

    /// Get a specific field from frontmatter
    public func getField(_ key: String, from content: String) -> String? {
        guard let (frontmatter, _) = parse(content) else {
            return nil
        }
        return frontmatter[key]
    }
}
