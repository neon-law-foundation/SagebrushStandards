import Foundation

struct SyncCommand: Command {
    let standardsDirectory: String
    let apiClient: SagebrushAPIClientProtocol

    init(standardsDirectory: String? = nil, apiClient: SagebrushAPIClientProtocol = SagebrushAPIClient()) {
        if let dir = standardsDirectory {
            self.standardsDirectory = dir
        } else {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            self.standardsDirectory = homeDirectory.appendingPathComponent("Standards").path
        }
        self.apiClient = apiClient
    }

    func run() async throws {
        let standardsURL = URL(fileURLWithPath: standardsDirectory)

        // Ensure ~/Standards directory exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: standardsURL.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            throw CommandError.setupFailed("~/Standards directory does not exist. Run 'standards setup' first.")
        }

        // Fetch projects from API
        print("Fetching projects from Sagebrush API...")
        let projects = try await apiClient.fetchProjects()
        print("✓ Found \(projects.count) projects")

        // Sync each project
        for project in projects {
            let projectURL = standardsURL.appendingPathComponent(project.name)

            if FileManager.default.fileExists(atPath: projectURL.path) {
                // Project directory exists - pull latest
                try await gitPull(in: projectURL, projectName: project.name)
            } else {
                // Create new project directory
                try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)
                print("✓ Created ~/Standards/\(project.name)")
            }
        }

        print("\n✓ Sync complete!")
    }

    private func gitPull(in directory: URL, projectName: String) async throws {
        // Check if directory is a git repository
        let gitDir = directory.appendingPathComponent(".git")
        guard FileManager.default.fileExists(atPath: gitDir.path) else {
            print("⚠️  ~/Standards/\(projectName) is not a git repository")
            return
        }

        // Run git pull
        print("Pulling latest changes for \(projectName)...")
        let process = Process()
        process.currentDirectoryURL = directory
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["pull"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            print("✓ Updated ~/Standards/\(projectName)")
        } else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            print("⚠️  Failed to pull \(projectName): \(output)")
        }
    }
}
