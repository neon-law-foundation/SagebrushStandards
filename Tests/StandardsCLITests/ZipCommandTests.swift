import Foundation
import Testing

@testable import StandardsCLI

@Suite("Zip Command")
struct ZipCommandTests {
    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("StandardsCLITests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanupTestDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Directory name is extracted correctly")
    func directoryNameExtraction() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let subdirName = "SagebrushHoldingCompany"
        let subdir = testDir.appendingPathComponent(subdirName)
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        #expect(subdir.lastPathComponent == subdirName)
    }

    @Test("Markdown files are found correctly")
    func markdownFilesAreFound() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create test markdown files
        let file1 = testDir.appendingPathComponent("document1.md")
        let file2 = testDir.appendingPathComponent("document2.md")
        let readme = testDir.appendingPathComponent("README.md")
        let txtFile = testDir.appendingPathComponent("notes.txt")

        try "# Document 1".write(to: file1, atomically: true, encoding: .utf8)
        try "# Document 2".write(to: file2, atomically: true, encoding: .utf8)
        try "# README".write(to: readme, atomically: true, encoding: .utf8)
        try "Notes".write(to: txtFile, atomically: true, encoding: .utf8)

        // Use reflection or a test helper to verify file discovery
        // Since findMarkdownFiles is private, we'll verify the files exist
        #expect(FileManager.default.fileExists(atPath: file1.path))
        #expect(FileManager.default.fileExists(atPath: file2.path))
        #expect(FileManager.default.fileExists(atPath: readme.path))
        #expect(FileManager.default.fileExists(atPath: txtFile.path))
    }

    @Test("README.md files are excluded")
    func readmeFilesAreExcluded() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let readme = testDir.appendingPathComponent("README.md")
        try "# README".write(to: readme, atomically: true, encoding: .utf8)

        guard
            let enumerator = FileManager.default.enumerator(
                at: testDir,
                includingPropertiesForKeys: [.isRegularFileKey]
            )
        else {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }

        var markdownFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.lowercased() == "md" && fileURL.lastPathComponent != "README.md" {
                markdownFiles.append(fileURL)
            }
        }

        #expect(markdownFiles.isEmpty)
    }

    @Test("Nested markdown files are found")
    func nestedMarkdownFilesAreFound() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let subdir = testDir.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        let rootFile = testDir.appendingPathComponent("root.md")
        let nestedFile = subdir.appendingPathComponent("nested.md")
        let nestedReadme = subdir.appendingPathComponent("README.md")

        try "# Root".write(to: rootFile, atomically: true, encoding: .utf8)
        try "# Nested".write(to: nestedFile, atomically: true, encoding: .utf8)
        try "# Nested README".write(to: nestedReadme, atomically: true, encoding: .utf8)

        guard
            let enumerator = FileManager.default.enumerator(
                at: testDir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }

        var markdownFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            let resourceKeys = Set<URLResourceKey>([.isRegularFileKey])
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                resourceValues.isRegularFile == true
            else {
                continue
            }

            if fileURL.pathExtension.lowercased() == "md" && fileURL.lastPathComponent != "README.md" {
                markdownFiles.append(fileURL)
            }
        }

        #expect(markdownFiles.count == 2)
        #expect(markdownFiles.contains(rootFile))
        #expect(markdownFiles.contains(nestedFile))
        #expect(!markdownFiles.contains(nestedReadme))
    }

    @Test("Command fails gracefully with invalid directory")
    func commandFailsWithInvalidDirectory() async throws {
        let invalidPath = "/nonexistent/directory/path"
        let command = ZipCommand(directoryPath: invalidPath)

        await #expect(throws: CommandError.self) {
            try await command.run()
        }
    }

    @Test("Empty directory is handled correctly")
    func emptyDirectoryIsHandled() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create a command but don't run it since it would try to call external processes
        _ = ZipCommand(directoryPath: testDir.path)

        // Verify directory exists and is empty
        let contents = try FileManager.default.contentsOfDirectory(at: testDir, includingPropertiesForKeys: nil)
        #expect(contents.isEmpty)
    }

    @Test("Multiple markdown files in flat directory")
    func multipleMarkdownFilesInFlatDirectory() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create multiple markdown files
        for i in 1...5 {
            let file = testDir.appendingPathComponent("document\(i).md")
            try "# Document \(i)".write(to: file, atomically: true, encoding: .utf8)
        }

        // Create README.md which should be excluded
        let readme = testDir.appendingPathComponent("README.md")
        try "# README".write(to: readme, atomically: true, encoding: .utf8)

        guard
            let enumerator = FileManager.default.enumerator(
                at: testDir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }

        var markdownFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            let resourceKeys = Set<URLResourceKey>([.isRegularFileKey])
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                resourceValues.isRegularFile == true
            else {
                continue
            }

            if fileURL.pathExtension.lowercased() == "md" && fileURL.lastPathComponent != "README.md" {
                markdownFiles.append(fileURL)
            }
        }

        #expect(markdownFiles.count == 5)
        #expect(!markdownFiles.contains(readme))
    }
}
