import Foundation
import Logging
import StandardsDAL
import StandardsRules

struct ImportCommand: Command {
    let directoryPath: String
    let gitRepositoryID: Int32
    let version: String

    func run() async throws {
        let logger = Logger(label: "standards-cli")
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

        print("📋 Validating markdown files in: \(url.path)")

        let rules: [Rule] = [
            F101_TitleRequired(),
            F102_RespondentTypeRequired(),
        ]
        let engine = RuleEngine(rules: rules)
        let lintResult = try engine.lint(directory: url)

        if !lintResult.isValid {
            print("❌ Found \(lintResult.totalViolationCount) violation(s) in \(lintResult.fileViolations.count) file(s):\n")

            for fileViolation in lintResult.fileViolations {
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

            print("❌ Validation failed. Please fix violations before importing.")
            throw CommandError.lintFailed
        }

        print("✅ All files valid. Starting import to database...\n")

        let dbManager = try await DatabaseManager()
        let database = dbManager.getDatabase()
        let notationService = NotationService(database: database)
        let importer = NotationImporter(notationService: notationService, logger: logger)

        let filesToImport = try collectMarkdownFiles(in: url)

        var importCount = 0
        var failCount = 0

        for fileURL in filesToImport {
            do {
                let notation = try await importer.importMarkdownFile(
                    fileURL,
                    gitRepositoryID: gitRepositoryID,
                    version: version
                )
                let relativePath = makeRelativePath(fileURL, from: url)
                print("✅ Imported: \(relativePath) -> \(notation.code ?? "unknown") - \(notation.title)")
                importCount += 1
            } catch let error as NotationError {
                let relativePath = makeRelativePath(fileURL, from: url)
                print("❌ Failed to import \(relativePath): \(error.errorDescription ?? error.localizedDescription)")
                failCount += 1
            } catch {
                let relativePath = makeRelativePath(fileURL, from: url)
                print("❌ Failed to import \(relativePath): \(error)")
                failCount += 1
            }
        }

        try await dbManager.shutdown()

        print("\n" + String(repeating: "=", count: 50))
        print("📊 Import Summary:")
        print("   ✅ Successfully imported: \(importCount) notation(s)")
        if failCount > 0 {
            print("   ❌ Failed: \(failCount) notation(s)")
        }
        print(String(repeating: "=", count: 50))

        if failCount > 0 {
            throw CommandError.setupFailed("Some imports failed")
        }
    }

    private func collectMarkdownFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        guard
            let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            throw CommandError.setupFailed("Cannot enumerate directory: \(directory.path)")
        }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            guard FileFilters.shouldValidate(fileURL) else { continue }
            files.append(fileURL)
        }
        return files
    }

    private func makeRelativePath(_ file: URL, from base: URL) -> String {
        base.path.isEmpty
            ? file.path : file.path.replacingOccurrences(of: base.path + "/", with: "")
    }
}
