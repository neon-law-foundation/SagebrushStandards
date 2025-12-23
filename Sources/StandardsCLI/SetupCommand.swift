import Foundation

struct SetupCommand: Command {
    let apiClient: SagebrushAPIClientProtocol
    let homeDirectory: URL
    let templateDirectory: URL

    init(
        apiClient: SagebrushAPIClientProtocol = SagebrushAPIClient(),
        homeDirectory: URL? = nil,
        templateDirectory: URL? = nil
    ) {
        self.apiClient = apiClient
        self.homeDirectory = homeDirectory ?? FileManager.default.homeDirectoryForCurrentUser
        self.templateDirectory =
            templateDirectory ?? URL(fileURLWithPath: "/Users/nick/Trifecta/NLF/SagebrushStandards/ClaudeTemplates")
    }

    func run() async throws {
        let standardsURL = homeDirectory.appendingPathComponent("Standards")

        // 1. Find or create ~/Standards
        try createDirectoryIfNeeded(at: standardsURL)
        print("✓ ~/Standards directory ready")

        // 2. Find or create ~/Standards/CLAUDE.md
        try await setupCLAUDETemplate(in: standardsURL)

        // 3. Set up Claude agents
        try await setupClaudeAgents(in: standardsURL)

        // 4. Set up Claude commands
        try await setupClaudeCommands(in: standardsURL)

        // 5. Fetch projects from API
        print("Fetching projects from Sagebrush API...")
        let projects = try await apiClient.fetchProjects()
        print("✓ Found \(projects.count) projects")

        // 6. Create project directories
        for project in projects {
            let projectURL = standardsURL.appendingPathComponent(project.name)
            try createDirectoryIfNeeded(at: projectURL)
            print("✓ Created ~/Standards/\(project.name)")
        }

        print("\n✓ Setup complete!")
    }

    private func createDirectoryIfNeeded(at url: URL) throws {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return  // Directory already exists
            } else {
                throw CommandError.setupFailed("\(url.path) exists but is not a directory")
            }
        }

        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw CommandError.setupFailed("Failed to create directory \(url.path): \(error.localizedDescription)")
        }
    }

    private func setupCLAUDETemplate(in standardsURL: URL) async throws {
        let claudeURL = standardsURL.appendingPathComponent("CLAUDE.md")

        // Check if CLAUDE.md already exists
        if FileManager.default.fileExists(atPath: claudeURL.path) {
            print("✓ ~/Standards/CLAUDE.md already exists")
            return
        }

        // Find source template
        let templateURL = templateDirectory.appendingPathComponent("CLAUDE.md")

        guard FileManager.default.fileExists(atPath: templateURL.path) else {
            throw CommandError.setupFailed("CLAUDE.md template not found at: \(templateURL.path)")
        }

        // Copy template
        do {
            try FileManager.default.copyItem(at: templateURL, to: claudeURL)
            print("✓ Created ~/Standards/CLAUDE.md")
        } catch {
            throw CommandError.setupFailed("Failed to copy CLAUDE.md: \(error.localizedDescription)")
        }
    }

    private func setupClaudeAgents(in standardsURL: URL) async throws {
        // Create ~/Standards/.claude/agents directory
        let claudeAgentsURL =
            standardsURL
            .appendingPathComponent(".claude")
            .appendingPathComponent("agents")
        try createDirectoryIfNeeded(at: claudeAgentsURL)

        // Set up markdown-formatter agent
        let markdownFormatterDestURL = claudeAgentsURL.appendingPathComponent("markdown-formatter.md")

        // Check if agent already exists
        if FileManager.default.fileExists(atPath: markdownFormatterDestURL.path) {
            print("✓ ~/Standards/.claude/agents/markdown-formatter.md already exists")
            return
        }

        // Find source agent
        let agentTemplateURL =
            templateDirectory
            .appendingPathComponent("agents")
            .appendingPathComponent("markdown-formatter.md")

        guard FileManager.default.fileExists(atPath: agentTemplateURL.path) else {
            throw CommandError.setupFailed("markdown-formatter.md agent not found at: \(agentTemplateURL.path)")
        }

        // Copy agent
        do {
            try FileManager.default.copyItem(at: agentTemplateURL, to: markdownFormatterDestURL)
            print("✓ Created ~/Standards/.claude/agents/markdown-formatter.md")
        } catch {
            throw CommandError.setupFailed("Failed to copy markdown-formatter.md: \(error.localizedDescription)")
        }
    }

    private func setupClaudeCommands(in standardsURL: URL) async throws {
        // Create ~/Standards/.claude/commands directory
        let claudeCommandsURL =
            standardsURL
            .appendingPathComponent(".claude")
            .appendingPathComponent("commands")
        try createDirectoryIfNeeded(at: claudeCommandsURL)

        // Set up format-markdown command
        let formatMarkdownDestURL = claudeCommandsURL.appendingPathComponent("format-markdown.md")

        // Check if command already exists
        if FileManager.default.fileExists(atPath: formatMarkdownDestURL.path) {
            print("✓ ~/Standards/.claude/commands/format-markdown.md already exists")
            return
        }

        // Find source command
        let commandTemplateURL =
            templateDirectory
            .appendingPathComponent("commands")
            .appendingPathComponent("format-markdown.md")

        guard FileManager.default.fileExists(atPath: commandTemplateURL.path) else {
            throw CommandError.setupFailed("format-markdown.md command not found at: \(commandTemplateURL.path)")
        }

        // Copy command
        do {
            try FileManager.default.copyItem(at: commandTemplateURL, to: formatMarkdownDestURL)
            print("✓ Created ~/Standards/.claude/commands/format-markdown.md")
        } catch {
            throw CommandError.setupFailed("Failed to copy format-markdown.md: \(error.localizedDescription)")
        }
    }
}
