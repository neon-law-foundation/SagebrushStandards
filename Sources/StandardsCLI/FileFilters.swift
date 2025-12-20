import Foundation

/// Shared file filtering logic for validators
public enum FileFilters {
    /// Determines if a file should be excluded from validation
    /// - Parameter url: The file URL to check
    /// - Returns: true if the file should be excluded, false otherwise
    public static func shouldExcludeFromValidation(_ url: URL) -> Bool {
        url.lastPathComponent == "README.md" || url.lastPathComponent == "CLAUDE.md"
    }

    /// Determines if a file is a Markdown file that should be validated
    /// - Parameter url: The file URL to check
    /// - Returns: true if the file is a Markdown file and should be validated
    public static func shouldValidate(_ url: URL) -> Bool {
        url.pathExtension == "md" && !shouldExcludeFromValidation(url)
    }
}
