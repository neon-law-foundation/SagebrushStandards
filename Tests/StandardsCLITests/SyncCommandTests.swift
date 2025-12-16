import Foundation
import Testing

@testable import StandardsCLI

@Suite("Sync Command Tests")
struct SyncCommandTests {
    func createTestDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SyncCommandTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    func cleanupTestDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Sync command creates project directories from API")
    func syncCommandCreatesProjectDirectories() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create mock API client with test projects
        let mockProjects = [
            Project(name: "TestProject1"),
            Project(name: "TestProject2"),
        ]
        let mockClient = MockSagebrushAPIClient(projects: mockProjects)

        let command = SyncCommand(standardsDirectory: testDir.path, apiClient: mockClient)
        try await command.run()

        // Verify project directories were created
        let project1URL = testDir.appendingPathComponent("TestProject1")
        let project2URL = testDir.appendingPathComponent("TestProject2")

        #expect(FileManager.default.fileExists(atPath: project1URL.path))
        #expect(FileManager.default.fileExists(atPath: project2URL.path))
    }

    @Test("Sync command handles empty project list")
    func syncCommandHandlesEmptyProjectList() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        let mockClient = MockSagebrushAPIClient(projects: [])
        let command = SyncCommand(standardsDirectory: testDir.path, apiClient: mockClient)

        try await command.run()

        // Should complete without error
    }

    @Test("Sync command skips existing directories")
    func syncCommandSkipsExistingDirectories() async throws {
        let testDir = try createTestDirectory()
        defer { cleanupTestDirectory(testDir) }

        // Create a project directory manually
        let existingProjectURL = testDir.appendingPathComponent("ExistingProject")
        try FileManager.default.createDirectory(at: existingProjectURL, withIntermediateDirectories: true)

        let mockProjects = [Project(name: "ExistingProject")]
        let mockClient = MockSagebrushAPIClient(projects: mockProjects)

        let command = SyncCommand(standardsDirectory: testDir.path, apiClient: mockClient)
        try await command.run()

        // Should not fail, directory should still exist
        #expect(FileManager.default.fileExists(atPath: existingProjectURL.path))
    }
}

// Mock API client for testing
struct MockSagebrushAPIClient: SagebrushAPIClientProtocol {
    let projects: [Project]

    func fetchProjects() async throws -> [Project] {
        projects
    }
}
