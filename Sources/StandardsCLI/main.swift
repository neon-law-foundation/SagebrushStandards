import Foundation

let arguments = CommandLine.arguments

func printUsage() {
    print(
        """
        Usage: standards <command> [arguments]

        Commands:
          lint <directory>                Validate Markdown files have lines ≤120 characters
          import <directory> --repo <id> --version <sha>
                                          Import validated Markdown notations to database
          pdf <file>                      Convert a standard Markdown file to PDF
                                          Validates the file first, strips frontmatter, and outputs to .pdf

        Examples:
          standards lint .
          standards import ./notations --repo 1 --version abc123
          standards pdf nevada.md
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
            let directoryPath = arguments.count > 2 ? arguments[2] : "."
            command = LintCommand(directoryPath: directoryPath)

        case "import":
            guard arguments.count > 2 else {
                print("Error: Missing directory argument for import command")
                print("Usage: standards import <directory> --repo <id> --version <sha>")
                exit(1)
            }

            let directoryPath = arguments[2]
            var gitRepositoryID: Int32?
            var version: String?

            var i = 3
            while i < arguments.count {
                if arguments[i] == "--repo", i + 1 < arguments.count {
                    gitRepositoryID = Int32(arguments[i + 1])
                    i += 2
                } else if arguments[i] == "--version", i + 1 < arguments.count {
                    version = arguments[i + 1]
                    i += 2
                } else {
                    i += 1
                }
            }

            guard let repoID = gitRepositoryID else {
                print("Error: Missing --repo argument")
                print("Usage: standards import <directory> --repo <id> --version <sha>")
                exit(1)
            }

            guard let ver = version else {
                print("Error: Missing --version argument")
                print("Usage: standards import <directory> --repo <id> --version <sha>")
                exit(1)
            }

            command = ImportCommand(
                directoryPath: directoryPath,
                gitRepositoryID: repoID,
                version: ver
            )

        case "pdf":
            guard arguments.count > 2 else {
                print("Error: Missing file argument for pdf command")
                print("Usage: standards pdf <file>")
                exit(1)
            }
            let filePath = arguments[2]
            command = PDFCommand(inputPath: filePath)

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
