import Foundation

struct LintCommand: Command {
    let directoryPath: String

    func run() async throws {
        let url: URL
        if directoryPath == "." {
            url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        } else {
            url = URL(fileURLWithPath: directoryPath)
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            print("Error: '\(directoryPath)' is not a valid directory")
            throw CommandError.invalidDirectory(directoryPath)
        }

        let engine = RuleEngine(rules: [
            S101_LineLength(),
            F101_TitleRequired(),
            F102_RespondentTypeRequired(),
        ])

        let result = try engine.lint(directory: url)

        if result.isValid {
            print("✓ All Markdown files pass all rules")
        } else {
            print(
                "✗ Found \(result.totalViolationCount) violation(s) in \(result.fileViolations.count) file(s):\n"
            )

            for fileViolation in result.fileViolations {
                let relativePath = makeRelativePath(fileViolation.file, from: url)
                print("\(relativePath):")

                for violation in fileViolation.violations {
                    var parts = ["[\(violation.ruleCode)]"]

                    if let line = violation.line {
                        parts.append("Line \(line):")
                    }

                    parts.append(violation.message)

                    if let context = violation.context, !context.isEmpty {
                        let contextStr = context.map { "\($0.key): \($0.value)" }.joined(
                            separator: ", "
                        )
                        parts.append("(\(contextStr))")
                    }

                    print("  " + parts.joined(separator: " "))
                }
                print("")
            }

            throw CommandError.lintFailed
        }
    }

    private func makeRelativePath(_ file: URL, from base: URL) -> String {
        base.path.isEmpty
            ? file.path : file.path.replacingOccurrences(of: base.path + "/", with: "")
    }
}

enum CommandError: Error, LocalizedError {
    case invalidDirectory(String)
    case lintFailed
    case unknownCommand(String)
    case missingArgument(String)
    case setupFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidDirectory(let path):
            return "Invalid directory: \(path)"
        case .lintFailed:
            return "Lint check failed"
        case .unknownCommand(let command):
            return "Unknown command: \(command)"
        case .missingArgument(let arg):
            return "Missing argument: \(arg)"
        case .setupFailed(let reason):
            return "Setup failed: \(reason)"
        }
    }
}
