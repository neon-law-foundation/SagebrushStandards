import Foundation

/// Validates that Markdown files have lines of 120 characters or less
public struct MarkdownValidator {
    private let maxLineLength = 120

    public init() {}

    /// Validates all Markdown files in a directory
    public func validate(directory: URL) throws -> ValidationResult {
        let fileManager = FileManager.default
        var violations: [FileViolation] = []

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
                violations.append(FileViolation(file: fileURL, violations: fileViolations))
            }
        }

        return ValidationResult(violations: violations)
    }

    /// Validates a single Markdown file
    public func validateFile(at url: URL) throws -> [LineViolation] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError.fileNotFound(url)
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var violations: [LineViolation] = []
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let length = line.count

            if length > maxLineLength {
                violations.append(
                    LineViolation(
                        lineNumber: lineNumber,
                        length: length,
                        maxLength: maxLineLength
                    )
                )
            }
        }

        return violations
    }
}

// MARK: - Models

public struct ValidationResult {
    public let violations: [FileViolation]

    public var isValid: Bool {
        violations.isEmpty
    }
}

public struct FileViolation {
    public let file: URL
    public let violations: [LineViolation]
}

public struct LineViolation {
    public let lineNumber: Int
    public let length: Int
    public let maxLength: Int
}

// MARK: - Errors

public enum ValidationError: Error, LocalizedError {
    case directoryNotAccessible(URL)
    case fileNotFound(URL)
    case invalidPath(String)

    public var errorDescription: String? {
        switch self {
        case .directoryNotAccessible(let url):
            return "Directory not accessible: \(url.path)"
        case .fileNotFound(let url):
            return "File not found: \(url.path)"
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        }
    }
}
