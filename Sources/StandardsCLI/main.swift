import Foundation

let arguments = CommandLine.arguments

func printUsage() {
    print(
        """
        Usage: standards <command> [arguments]

        Commands:
          lint <directory>    Validate Markdown files have lines ≤120 characters
          import <directory>  Import validated Markdown notations to database
                              Auto-detects git repository and commit SHA
                              Requires clean working tree (no uncommitted changes)
          pdf <file>          Convert a standard Markdown file to PDF
                              Validates the file first, strips frontmatter, and outputs to .pdf

        Examples:
          standards lint .
          standards import ./notations
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
            let directoryPath = arguments.count > 2 ? arguments[2] : "."
            command = ImportCommand(directoryPath: directoryPath)

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
