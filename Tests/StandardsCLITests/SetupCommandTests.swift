import Foundation
import Testing

@testable import StandardsCLI

@Suite("Setup Command Tests")
struct SetupCommandTests {
    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SetupCommandTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanupTestDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func createMockTemplates(in directory: URL) throws {
        // Create mock CLAUDE.md template
        let claudeURL = directory.appendingPathComponent("CLAUDE.md")
        try "# Mock CLAUDE.md\n\nTest content for CLAUDE template.".write(
            to: claudeURL,
            atomically: true,
            encoding: .utf8
        )

        // Create mock agents directory and markdown-formatter.md
        let agentsURL = directory.appendingPathComponent("agents")
        try FileManager.default.createDirectory(at: agentsURL, withIntermediateDirectories: true)

        let formatterURL = agentsURL.appendingPathComponent("markdown-formatter.md")
        try "# Mock Markdown Formatter\n\nTest content for formatter agent.".write(
            to: formatterURL,
            atomically: true,
            encoding: .utf8
        )
    }

    @Test("Setup command creates Standards directory structure")
    func setupCommandCreatesStandardsStructure() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create mock template directory
        let templateDir = testDir.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)
        try createMockTemplates(in: templateDir)

        // Create mock home directory
        let mockHomeURL = testDir.appendingPathComponent("home")
        try FileManager.default.createDirectory(at: mockHomeURL, withIntermediateDirectories: true)

        // Create mock API client
        let mockClient = MockSagebrushAPIClient(projects: [])

        // Run setup command
        let command = SetupCommand(
            apiClient: mockClient,
            homeDirectory: mockHomeURL,
            templateDirectory: templateDir
        )
        try await command.run()

        // Verify ~/Standards directory was created
        let standardsURL = mockHomeURL.appendingPathComponent("Standards")
        #expect(FileManager.default.fileExists(atPath: standardsURL.path))

        // Verify CLAUDE.md was copied
        let claudeURL = standardsURL.appendingPathComponent("CLAUDE.md")
        #expect(FileManager.default.fileExists(atPath: claudeURL.path))

        // Verify .claude/agents directory was created
        let agentsURL =
            standardsURL
            .appendingPathComponent(".claude")
            .appendingPathComponent("agents")
        #expect(FileManager.default.fileExists(atPath: agentsURL.path))

        // Verify markdown-formatter.md was copied
        let formatterURL = agentsURL.appendingPathComponent("markdown-formatter.md")
        #expect(FileManager.default.fileExists(atPath: formatterURL.path))
    }

    @Test("Setup command copies correct CLAUDE.md content")
    func setupCommandCopiesCorrectClaudeContent() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create mock template directory with specific content
        let templateDir = testDir.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)
        try createMockTemplates(in: templateDir)

        let mockHomeURL = testDir.appendingPathComponent("home")
        try FileManager.default.createDirectory(at: mockHomeURL, withIntermediateDirectories: true)

        let mockClient = MockSagebrushAPIClient(projects: [])
        let command = SetupCommand(
            apiClient: mockClient,
            homeDirectory: mockHomeURL,
            templateDirectory: templateDir
        )
        try await command.run()

        // Verify content was copied correctly
        let claudeURL = mockHomeURL.appendingPathComponent("Standards/CLAUDE.md")
        let content = try String(contentsOf: claudeURL, encoding: .utf8)
        #expect(content.contains("Mock CLAUDE.md"))
        #expect(content.contains("Test content for CLAUDE template"))
    }

    @Test("Setup command copies correct agent content")
    func setupCommandCopiesCorrectAgentContent() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let templateDir = testDir.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)
        try createMockTemplates(in: templateDir)

        let mockHomeURL = testDir.appendingPathComponent("home")
        try FileManager.default.createDirectory(at: mockHomeURL, withIntermediateDirectories: true)

        let mockClient = MockSagebrushAPIClient(projects: [])
        let command = SetupCommand(
            apiClient: mockClient,
            homeDirectory: mockHomeURL,
            templateDirectory: templateDir
        )
        try await command.run()

        // Verify agent content was copied correctly
        let formatterURL = mockHomeURL.appendingPathComponent("Standards/.claude/agents/markdown-formatter.md")
        let content = try String(contentsOf: formatterURL, encoding: .utf8)
        #expect(content.contains("Mock Markdown Formatter"))
        #expect(content.contains("Test content for formatter agent"))
    }

    @Test("Setup command skips existing CLAUDE.md file")
    func setupCommandSkipsExistingClaudeFile() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let templateDir = testDir.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)
        try createMockTemplates(in: templateDir)

        let mockHomeURL = testDir.appendingPathComponent("home")
        let standardsURL = mockHomeURL.appendingPathComponent("Standards")
        try FileManager.default.createDirectory(at: standardsURL, withIntermediateDirectories: true)

        // Create existing CLAUDE.md with different content
        let claudeURL = standardsURL.appendingPathComponent("CLAUDE.md")
        let existingContent = "# Existing CLAUDE.md\n\nThis should not be overwritten."
        try existingContent.write(to: claudeURL, atomically: true, encoding: .utf8)

        let mockClient = MockSagebrushAPIClient(projects: [])
        let command = SetupCommand(
            apiClient: mockClient,
            homeDirectory: mockHomeURL,
            templateDirectory: templateDir
        )
        try await command.run()

        // Verify existing content was NOT overwritten
        let content = try String(contentsOf: claudeURL, encoding: .utf8)
        #expect(content.contains("Existing CLAUDE.md"))
        #expect(!content.contains("Mock CLAUDE.md"))
    }

    @Test("Setup command skips existing agent file")
    func setupCommandSkipsExistingAgentFile() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let templateDir = testDir.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)
        try createMockTemplates(in: templateDir)

        let mockHomeURL = testDir.appendingPathComponent("home")
        let standardsURL = mockHomeURL.appendingPathComponent("Standards")
        let agentsURL = standardsURL.appendingPathComponent(".claude/agents")
        try FileManager.default.createDirectory(at: agentsURL, withIntermediateDirectories: true)

        // Create existing agent file with different content
        let formatterURL = agentsURL.appendingPathComponent("markdown-formatter.md")
        let existingContent = "# Existing Formatter\n\nThis should not be overwritten."
        try existingContent.write(to: formatterURL, atomically: true, encoding: .utf8)

        let mockClient = MockSagebrushAPIClient(projects: [])
        let command = SetupCommand(
            apiClient: mockClient,
            homeDirectory: mockHomeURL,
            templateDirectory: templateDir
        )
        try await command.run()

        // Verify existing content was NOT overwritten
        let content = try String(contentsOf: formatterURL, encoding: .utf8)
        #expect(content.contains("Existing Formatter"))
        #expect(!content.contains("Mock Markdown Formatter"))
    }

    @Test("Setup command creates project directories from API")
    func setupCommandCreatesProjectDirectories() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let templateDir = testDir.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)
        try createMockTemplates(in: templateDir)

        let mockHomeURL = testDir.appendingPathComponent("home")
        try FileManager.default.createDirectory(at: mockHomeURL, withIntermediateDirectories: true)

        // Create mock API client with test projects
        let mockProjects = [
            Project(name: "Project1"),
            Project(name: "Project2"),
            Project(name: "Project3"),
        ]
        let mockClient = MockSagebrushAPIClient(projects: mockProjects)

        let command = SetupCommand(
            apiClient: mockClient,
            homeDirectory: mockHomeURL,
            templateDirectory: templateDir
        )
        try await command.run()

        // Verify project directories were created
        let standardsURL = mockHomeURL.appendingPathComponent("Standards")
        let project1URL = standardsURL.appendingPathComponent("Project1")
        let project2URL = standardsURL.appendingPathComponent("Project2")
        let project3URL = standardsURL.appendingPathComponent("Project3")

        #expect(FileManager.default.fileExists(atPath: project1URL.path))
        #expect(FileManager.default.fileExists(atPath: project2URL.path))
        #expect(FileManager.default.fileExists(atPath: project3URL.path))
    }

    @Test("Setup command handles missing CLAUDE.md template")
    func setupCommandHandlesMissingClaudeTemplate() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create template directory without CLAUDE.md
        let templateDir = testDir.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)

        let mockHomeURL = testDir.appendingPathComponent("home")
        try FileManager.default.createDirectory(at: mockHomeURL, withIntermediateDirectories: true)

        let mockClient = MockSagebrushAPIClient(projects: [])
        let command = SetupCommand(
            apiClient: mockClient,
            homeDirectory: mockHomeURL,
            templateDirectory: templateDir
        )

        // Should throw error when template is missing
        await #expect(throws: CommandError.self) {
            try await command.run()
        }
    }

    @Test("Setup command handles missing agent template")
    func setupCommandHandlesMissingAgentTemplate() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create template directory with CLAUDE.md but without agent
        let templateDir = testDir.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)

        let claudeURL = templateDir.appendingPathComponent("CLAUDE.md")
        try "# Mock CLAUDE.md".write(to: claudeURL, atomically: true, encoding: .utf8)

        let mockHomeURL = testDir.appendingPathComponent("home")
        try FileManager.default.createDirectory(at: mockHomeURL, withIntermediateDirectories: true)

        let mockClient = MockSagebrushAPIClient(projects: [])
        let command = SetupCommand(
            apiClient: mockClient,
            homeDirectory: mockHomeURL,
            templateDirectory: templateDir
        )

        // Should throw error when agent template is missing
        await #expect(throws: CommandError.self) {
            try await command.run()
        }
    }
}
