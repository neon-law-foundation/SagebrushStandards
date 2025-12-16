import Foundation

struct ZipCommand: Command {
    let directoryPath: String

    func run() async throws {
        // Resolve path to URL
        let url: URL
        if directoryPath == "." {
            url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        } else {
            url = URL(fileURLWithPath: directoryPath, isDirectory: true)
        }

        // Validate directory exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            print("Error: '\(directoryPath)' is not a valid directory")
            throw CommandError.invalidDirectory(directoryPath)
        }

        // Get directory name for zip file
        let directoryName = url.lastPathComponent
        print("📦 Creating zip for directory: \(directoryName)")

        // Find all markdown files (except README.md)
        let markdownFiles = try findMarkdownFiles(in: url)

        guard !markdownFiles.isEmpty else {
            print("⚠️  No markdown files found (excluding README.md)")
            return
        }

        print("📄 Found \(markdownFiles.count) markdown file(s) to convert")

        // Create temporary directory for .docx files
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            // Clean up temporary directory
            try? FileManager.default.removeItem(at: tempDir)
        }

        var docxFiles: [URL] = []

        // Convert each markdown file to .docx
        for markdownFile in markdownFiles {
            print("🔄 Converting \(markdownFile.lastPathComponent)...")
            let docxFile = try await convertToDocx(markdownFile: markdownFile, outputDir: tempDir)
            docxFiles.append(docxFile)
        }

        print("✅ Converted \(docxFiles.count) file(s) to .docx")

        // Create zip file in the original directory
        let zipFile = url.appendingPathComponent("\(directoryName).zip")

        // Remove existing zip if present
        if FileManager.default.fileExists(atPath: zipFile.path) {
            try FileManager.default.removeItem(at: zipFile)
        }

        print("🗜️  Creating zip file: \(zipFile.lastPathComponent)")
        try await createZip(files: docxFiles, zipFile: zipFile)

        print("✅ Created: \(zipFile.path)")

        // Open Mail.app with the zip file
        print("📧 Opening Mail.app with attachment...")
        try await openMail(withAttachment: zipFile, subject: "\(directoryName) docs")

        print("✅ Done! Mail.app draft created with \(directoryName).zip")
    }

    private func findMarkdownFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey]

        guard
            let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
            )
        else {
            throw CommandError.invalidDirectory(directory.path)
        }

        var markdownFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                resourceValues.isRegularFile == true
            else {
                continue
            }

            // Include .md files but exclude README.md
            if fileURL.pathExtension.lowercased() == "md" && fileURL.lastPathComponent != "README.md" {
                markdownFiles.append(fileURL)
            }
        }

        return markdownFiles.sorted { $0.path < $1.path }
    }

    private func convertToDocx(markdownFile: URL, outputDir: URL) async throws -> URL {
        let outputFile = outputDir.appendingPathComponent(
            markdownFile.deletingPathExtension().lastPathComponent + ".docx"
        )

        // Find pandoc in common locations
        let pandocPaths = [
            "/opt/homebrew/bin/pandoc",
            "/usr/local/bin/pandoc",
            "/usr/bin/pandoc",
        ]

        guard let pandocPath = pandocPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            throw CommandError.pandocFailed("pandoc not found. Please install pandoc: brew install pandoc")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: pandocPath)
        process.arguments = [
            markdownFile.path,
            "-o", outputFile.path,
            "--from=markdown",
            "--to=docx",
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw CommandError.pandocFailed("Failed to convert \(markdownFile.lastPathComponent): \(output)")
        }

        return outputFile
    }

    private func createZip(files: [URL], zipFile: URL) async throws {
        // Change to the directory containing the files to avoid full paths in zip
        let workingDir = files.first?.deletingLastPathComponent().path ?? ""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = URL(fileURLWithPath: workingDir)

        // Build arguments: zip -j output.zip file1 file2 file3
        var arguments = ["-j", zipFile.path]
        arguments.append(contentsOf: files.map { $0.lastPathComponent })
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw CommandError.zipFailed("Failed to create zip: \(output)")
        }
    }

    private func openMail(withAttachment attachment: URL, subject: String) async throws {
        // Use AppleScript to create a new email with subject and attachment
        let appleScript = """
            tell application "Mail"
                set newMessage to make new outgoing message with properties {subject:"\(subject)", visible:true}
                tell newMessage
                    make new attachment with properties {file name:"\(attachment.path)"} at after the last paragraph
                end tell
                activate
            end tell
            """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw CommandError.mailFailed("Failed to open Mail.app: \(output)")
        }
    }
}

// Extend CommandError with new cases
extension CommandError {
    static func pandocFailed(_ message: String) -> CommandError {
        .setupFailed(message)
    }

    static func zipFailed(_ message: String) -> CommandError {
        .setupFailed(message)
    }

    static func mailFailed(_ message: String) -> CommandError {
        .setupFailed(message)
    }
}
