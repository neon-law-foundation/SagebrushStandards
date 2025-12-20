import Foundation
import Testing

@testable import StandardsCLI

@Suite("File Filters")
struct FileFiltersTests {
    @Test("README.md files should be excluded from validation")
    func readmeFilesExcluded() {
        let readmeURL = URL(fileURLWithPath: "/some/path/README.md")
        #expect(FileFilters.shouldExcludeFromValidation(readmeURL))
        #expect(!FileFilters.shouldValidate(readmeURL))
    }

    @Test("Regular markdown files should not be excluded")
    func regularMarkdownFilesNotExcluded() {
        let regularURL = URL(fileURLWithPath: "/some/path/document.md")
        #expect(!FileFilters.shouldExcludeFromValidation(regularURL))
        #expect(FileFilters.shouldValidate(regularURL))
    }

    @Test("Non-markdown files should not be validated")
    func nonMarkdownFilesNotValidated() {
        let txtURL = URL(fileURLWithPath: "/some/path/file.txt")
        #expect(!FileFilters.shouldValidate(txtURL))
    }

    @Test("README.md in subdirectory should be excluded")
    func readmeInSubdirectoryExcluded() {
        let nestedReadmeURL = URL(fileURLWithPath: "/some/deep/path/README.md")
        #expect(FileFilters.shouldExcludeFromValidation(nestedReadmeURL))
        #expect(!FileFilters.shouldValidate(nestedReadmeURL))
    }

    @Test("File with README in name but not README.md should be validated")
    func readmeLikeFilesValidated() {
        let readmeLikeURL = URL(fileURLWithPath: "/some/path/README-draft.md")
        #expect(!FileFilters.shouldExcludeFromValidation(readmeLikeURL))
        #expect(FileFilters.shouldValidate(readmeLikeURL))
    }

    @Test("Lowercase readme.md should not be excluded (case sensitive)")
    func lowercaseReadmeNotExcluded() {
        let lowercaseURL = URL(fileURLWithPath: "/some/path/readme.md")
        #expect(!FileFilters.shouldExcludeFromValidation(lowercaseURL))
        #expect(FileFilters.shouldValidate(lowercaseURL))
    }
}
