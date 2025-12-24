import Foundation

struct LintCommand: Command {
    let directoryPath: String
    let fix: Bool

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

        // Run validations
        let markdownValidator = MarkdownValidator()
        let frontmatterValidator = FrontmatterValidator()

        let markdownResult = try markdownValidator.validate(directory: url)
        let frontmatterResult = try frontmatterValidator.validate(directory: url)

        // Print results
        let allValid = markdownResult.isValid && frontmatterResult.isValid

        if allValid {
            print("✓ All Markdown files have lines of 120 characters or less")
            print("✓ All Markdown files have frontmatter with title and respondent_type")
        } else {
            // Print line length violations
            if !markdownResult.isValid {
                print("✗ Found line length violations:\n")

                for fileViolation in markdownResult.violations {
                    let relativePath =
                        url.path.isEmpty
                        ? fileViolation.file.path
                        : fileViolation.file.path.replacingOccurrences(of: url.path + "/", with: "")
                    print("\(relativePath):")

                    for violation in fileViolation.violations {
                        print(
                            "  Line \(violation.lineNumber): \(violation.length) characters "
                                + "(exceeds \(violation.maxLength))"
                        )
                    }
                    print("")
                }
            }

            // Print frontmatter violations
            if !frontmatterResult.isValid {
                print("✗ Found frontmatter violations:\n")

                for fileViolation in frontmatterResult.violations {
                    let relativePath =
                        url.path.isEmpty
                        ? fileViolation.file.path
                        : fileViolation.file.path.replacingOccurrences(of: url.path + "/", with: "")
                    print("\(relativePath):")

                    for violation in fileViolation.violations {
                        print("  \(violation.type.message)")
                    }
                    print("")
                }
            }

            if fix {
                // Only auto-fix line length violations
                if !markdownResult.isValid {
                    print("\n🔧 Auto-fixing line length violations...\n")

                    for fileViolation in markdownResult.violations {
                        let relativePath =
                            url.path.isEmpty
                            ? fileViolation.file.path
                            : fileViolation.file.path.replacingOccurrences(of: url.path + "/", with: "")
                        print("Fixing: \(relativePath)")

                        try await fixFile(fileViolation.file)
                    }

                    print("\n✓ Auto-fix complete. Running validation again...\n")

                    // Re-run validation
                    let newMarkdownResult = try markdownValidator.validate(directory: url)
                    let newFrontmatterResult = try frontmatterValidator.validate(directory: url)

                    if newMarkdownResult.isValid && newFrontmatterResult.isValid {
                        print("✓ All Markdown files now have lines of 120 characters or less")
                        print("✓ All Markdown files have frontmatter with title and respondent_type")
                    } else {
                        if !newMarkdownResult.isValid {
                            print("⚠️  Some line length violations could not be fixed automatically:")
                            for fileViolation in newMarkdownResult.violations {
                                let relativePath =
                                    url.path.isEmpty
                                    ? fileViolation.file.path
                                    : fileViolation.file.path.replacingOccurrences(
                                        of: url.path + "/",
                                        with: ""
                                    )
                                print(
                                    "  \(relativePath): \(fileViolation.violations.count) violations remaining"
                                )
                            }
                        }
                        if !newFrontmatterResult.isValid {
                            print("\n⚠️  Frontmatter violations cannot be auto-fixed:")
                            for fileViolation in newFrontmatterResult.violations {
                                let relativePath =
                                    url.path.isEmpty
                                    ? fileViolation.file.path
                                    : fileViolation.file.path.replacingOccurrences(
                                        of: url.path + "/",
                                        with: ""
                                    )
                                print("  \(relativePath): must add frontmatter with title and respondent_type manually")
                            }
                        }
                        throw CommandError.lintFailed
                    }
                } else if !frontmatterResult.isValid {
                    print("\n⚠️  Frontmatter violations cannot be auto-fixed. Please add frontmatter manually.")
                    throw CommandError.lintFailed
                }
            } else {
                var instructions = "\n📝 Fix Instructions:\n"

                if !markdownResult.isValid {
                    instructions += """

                        Line Length Violations:
                        All lines in Markdown files must be ≤120 characters. To fix these violations:

                        1. Break long lines at natural boundaries (spaces, punctuation)
                        2. Keep each line as close to 120 characters as possible without exceeding it
                        3. Maintain readability and proper Markdown formatting
                        4. For long URLs or code, consider using reference-style links

                        Run 'standards lint . --fix' to automatically fix line length violations.

                        """
                }

                if !frontmatterResult.isValid {
                    instructions += """

                        Frontmatter Violations:
                        All Markdown files must have YAML frontmatter with a title field and a respondent_type field.
                        To fix these violations:

                        1. Add frontmatter at the beginning of the file
                        2. Include a 'title' field with a non-empty value
                        3. Include a 'respondent_type' field with one of: entity, person, person_and_entity

                        Example:
                        ---
                        title: Document Title Here
                        respondent_type: person
                        ---

                        # Your content here

                        Note: Frontmatter violations cannot be auto-fixed. Please add frontmatter manually.

                        """
                }

                instructions += "Run 'standards lint .' again to verify after making changes."
                print(instructions)

                throw CommandError.lintFailed
            }
        }
    }

    private func fixFile(_ file: URL) async throws {
        let prompt = """
            Fix the line length violations in the file at \(file.path).

            All lines in Markdown files must be ≤120 characters. Please:

            1. Break long lines at natural boundaries (spaces, punctuation)
            2. Keep each line as close to 120 characters as possible without exceeding it
            3. Maintain readability and proper Markdown formatting
            4. For long URLs or code, consider using reference-style links
            5. DO NOT change the meaning or content, only reformat for line length

            Edit the file to fix all line length violations.
            """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/claude")
        process.arguments = ["--dangerously-skip-permissions", "--print", prompt]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            print("⚠️  Failed to fix \(file.lastPathComponent): \(output)")
            throw CommandError.lintFailed
        }
    }
}

enum CommandError: Error, LocalizedError {
    case invalidDirectory(String)
    case lintFailed
    case unknownCommand(String)
    case missingArgument(String)
    case setupFailed(String)
    case voiceCheckFailed(String)

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
        case .voiceCheckFailed(let file):
            return "Voice check failed for file: \(file)"
        }
    }
}
