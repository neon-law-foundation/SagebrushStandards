import Foundation

struct VoiceCommand: Command {
    let directoryPath: String

    func run() async throws {
        // Resolve path to URL
        let url: URL
        if directoryPath == "." {
            url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        } else {
            url = URL(fileURLWithPath: directoryPath)
        }

        // Validate directory exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            print("Error: '\(directoryPath)' is not a valid directory")
            throw CommandError.invalidDirectory(directoryPath)
        }

        // Find all markdown files
        let markdownFiles = try findMarkdownFiles(in: url)

        if markdownFiles.isEmpty {
            print("No Markdown files found in \(directoryPath)")
            return
        }

        print("Found \(markdownFiles.count) Markdown file(s) in \(directoryPath)")
        print("Running voice analysis with Claude...\n")

        // Run claude on each file
        for file in markdownFiles {
            let relativePath = file.path.replacingOccurrences(of: url.path + "/", with: "")
            print("Processing: \(relativePath)")

            try await runClaudeVoiceCheck(on: file)
        }

        print("\n✓ Voice analysis complete")
    }

    func findMarkdownFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        guard
            let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        var markdownFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }
            guard fileURL.lastPathComponent != "README.md" else { continue }

            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if resourceValues.isRegularFile == true {
                markdownFiles.append(fileURL)
            }
        }

        return markdownFiles.sorted { $0.path < $1.path }
    }

    private func runClaudeVoiceCheck(on file: URL) async throws {
        let prompt = """
            Review the file at \(file.path) according to the writing style and tone requirements in \
            /Users/nick/Trifecta/NLF/SagebrushStandards/CLAUDE.md.

            Specifically check for:
            1. Active voice (avoid passive constructions)
            2. No pronouns - reference people by their role (e.g., "executor", "stockholder", "secretary") instead of \
            "he/she/they"
            3. Clear, precise legal language
            4. Proper term definitions before use
            5. Logical structure with appropriate headings

            If you find any issues, edit the file to fix them. Focus on voice and tone improvements only - do not change \
            the legal substance or meaning of the content.

            Ensure all edits maintain compliance with the Standards specification (all lines ≤120 characters).
            """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/claude")
        process.arguments = ["--dangerously-skip-permissions", "--print", prompt]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print(output)
        }

        guard process.terminationStatus == 0 else {
            throw CommandError.voiceCheckFailed(file.lastPathComponent)
        }
    }
}
