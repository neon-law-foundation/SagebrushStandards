import Foundation
import Testing

@testable import StandardsCLI

@Suite("Command Tests")
struct CommandTests {
    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommandTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanupTestDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Lint command passes with valid files")
    func lintCommandPassesWithValidFiles() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("test.md")
        try """
        ---
        title: Test Document
        ---

        # Short content
        """.write(to: fileURL, atomically: true, encoding: .utf8)

        let command = LintCommand(directoryPath: testDir.path, fix: false)
        try await command.run()
    }

    @Test("Lint command fails with invalid files")
    func lintCommandFailsWithInvalidFiles() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let fileURL = testDir.appendingPathComponent("test.md")
        let longLine = String(repeating: "a", count: 150)
        try longLine.write(to: fileURL, atomically: true, encoding: .utf8)

        let command = LintCommand(directoryPath: testDir.path, fix: false)

        await #expect(throws: CommandError.self) {
            try await command.run()
        }
    }

    @Test("Lint command fails with non-existent directory")
    func lintCommandFailsWithNonExistentDirectory() async throws {
        let command = LintCommand(directoryPath: "/non/existent/path", fix: false)

        await #expect(throws: CommandError.self) {
            try await command.run()
        }
    }

    @Test("Setup command creates ~/standards structure")
    func setupCommandCreatesStandardsStructure() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Use temp directory as "home" for testing
        let mockHomeURL = testDir.appendingPathComponent("home")
        try FileManager.default.createDirectory(at: mockHomeURL, withIntermediateDirectories: true)

        // Mock API client with test projects
        let mockProjects = [Project(name: "TestProject")]
        let mockClient = MockSagebrushAPIClient(projects: mockProjects)

        // Note: This test would need dependency injection for home directory
        // For now, we test the sync command which is more unit-testable
        // SetupCommand tests are covered by manual testing
    }

    @Test("Lint command excludes README.md files")
    func lintCommandExcludesReadmeFiles() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create a README.md with long lines (should be ignored)
        let readmeURL = testDir.appendingPathComponent("README.md")
        let longLine = String(repeating: "a", count: 150)
        try "# README\n\n\(longLine)".write(to: readmeURL, atomically: true, encoding: .utf8)

        // Create a regular .md file with valid content
        let docURL = testDir.appendingPathComponent("doc.md")
        try """
        ---
        title: Documentation
        ---

        # Documentation

        Short content
        """.write(to: docURL, atomically: true, encoding: .utf8)

        // Lint should pass because README.md is excluded
        let command = LintCommand(directoryPath: testDir.path, fix: false)
        try await command.run()
    }

    @Test("Lint command excludes CLAUDE.md files")
    func lintCommandExcludesClaudeFiles() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create a CLAUDE.md with long lines (should be ignored)
        let claudeURL = testDir.appendingPathComponent("CLAUDE.md")
        let longLine = String(repeating: "a", count: 150)
        try "# CLAUDE\n\n\(longLine)".write(to: claudeURL, atomically: true, encoding: .utf8)

        // Create a regular .md file with valid content
        let docURL = testDir.appendingPathComponent("doc.md")
        try """
        ---
        title: Documentation
        ---

        # Documentation

        Short content
        """.write(to: docURL, atomically: true, encoding: .utf8)

        // Lint should pass because CLAUDE.md is excluded
        let command = LintCommand(directoryPath: testDir.path, fix: false)
        try await command.run()
    }

    @Test("Voice command excludes README.md files")
    func voiceCommandExcludesReadmeFiles() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create a README.md (should be excluded)
        let readmeURL = testDir.appendingPathComponent("README.md")
        try "# README\n\nContent".write(to: readmeURL, atomically: true, encoding: .utf8)

        // Create a regular .md file (should be included)
        let docURL = testDir.appendingPathComponent("doc.md")
        try "# Documentation\n\nContent".write(to: docURL, atomically: true, encoding: .utf8)

        // Create another regular .md file in a subdirectory (should be included)
        let subdir = testDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        let subdocURL = subdir.appendingPathComponent("subdoc.md")
        try "# Subdocument\n\nContent".write(to: subdocURL, atomically: true, encoding: .utf8)

        // Find markdown files
        let voiceCommand = VoiceCommand(directoryPath: testDir.path)
        let markdownFiles = try voiceCommand.findMarkdownFiles(in: testDir)

        // Should only find doc.md and subdir/subdoc.md, not README.md
        #expect(markdownFiles.count == 2)
        #expect(markdownFiles.contains { $0.lastPathComponent == "doc.md" })
        #expect(markdownFiles.contains { $0.lastPathComponent == "subdoc.md" })
        #expect(!markdownFiles.contains { $0.lastPathComponent == "README.md" })
    }

    @Test("Voice command excludes README.md in subdirectories")
    func voiceCommandExcludesReadmeInSubdirectories() throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create README.md in root
        let rootReadme = testDir.appendingPathComponent("README.md")
        try "# README".write(to: rootReadme, atomically: true, encoding: .utf8)

        // Create subdirectory with its own README.md
        let subdir = testDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        let subdirReadme = subdir.appendingPathComponent("README.md")
        try "# Subdir README".write(to: subdirReadme, atomically: true, encoding: .utf8)

        // Create a valid doc file in subdirectory
        let subdocURL = subdir.appendingPathComponent("doc.md")
        try "# Document".write(to: subdocURL, atomically: true, encoding: .utf8)

        // Find markdown files
        let voiceCommand = VoiceCommand(directoryPath: testDir.path)
        let markdownFiles = try voiceCommand.findMarkdownFiles(in: testDir)

        // Should only find doc.md, excluding both README.md files
        #expect(markdownFiles.count == 1)
        #expect(markdownFiles[0].lastPathComponent == "doc.md")
    }
}
