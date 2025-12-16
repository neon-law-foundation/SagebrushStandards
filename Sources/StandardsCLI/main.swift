import Foundation

let arguments = CommandLine.arguments

func printUsage() {
    print(
        """
        Usage: standards <command> [arguments]

        Commands:
          lint <directory> [--fix]    Validate Markdown files have lines ≤120 characters
                                      Use --fix to automatically correct violations
          voice <directory>           Check Markdown files for active voice and tone compliance
          setup                       Create ~/Standards structure and fetch projects
          sync                        Sync all projects (git pull existing repos)
          zip [directory]             Convert Markdown files to .docx, zip them, and open Mail.app
                                      Excludes README.md files

        Examples:
          standards lint .
          standards lint . --fix
          standards voice ShookFamily/Estate
          standards setup
          standards sync
          standards zip
          standards zip SagebrushHoldingCompany
        """
    )
}

Task {
    do {
        guard arguments.count > 1 else {
            printUsage()
            exit(1)
        }

        let commandName = arguments[1]
        let command: Command

        switch commandName {
        case "lint":
            var directoryPath = "."
            var fix = false

            // Parse arguments for lint command
            for i in 2..<arguments.count {
                let arg = arguments[i]
                if arg == "--fix" {
                    fix = true
                } else if !arg.starts(with: "-") {
                    directoryPath = arg
                }
            }

            command = LintCommand(directoryPath: directoryPath, fix: fix)

        case "voice":
            let directoryPath = arguments.count > 2 ? arguments[2] : "."
            command = VoiceCommand(directoryPath: directoryPath)

        case "setup":
            command = SetupCommand()

        case "sync":
            command = SyncCommand()

        case "zip":
            let directoryPath = arguments.count > 2 ? arguments[2] : "."
            command = ZipCommand(directoryPath: directoryPath)

        case "--help", "-h":
            printUsage()
            exit(0)

        default:
            throw CommandError.unknownCommand(commandName)
        }

        try await command.run()
        exit(0)
    } catch let error as CommandError {
        switch error {
        case .lintFailed:
            exit(1)
        default:
            print("Error: \(error.localizedDescription)")
            exit(1)
        }
    } catch {
        print("Error: \(error.localizedDescription)")
        exit(1)
    }
}

dispatchMain()
