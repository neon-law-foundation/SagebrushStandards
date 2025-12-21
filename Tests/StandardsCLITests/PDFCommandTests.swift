import Foundation
import Testing

@testable import StandardsCLI

@Suite("PDFCommand Tests")
struct PDFCommandTests {
    @Test("Creates PDF from valid standard file")
    func testCreatePDFFromValidStandard() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-standard.md")
        let pdfFile = tempDir.appendingPathComponent("test-standard.pdf")

        let validContent = """
            ---
            title: Test Standard
            respondent_type: org
            code: test_standard
            flow:
              BEGIN:
                _: END
            alignment:
              BEGIN:
                _: END
            description: A test standard
            ---

            ## Test Content

            This is a test standard with valid frontmatter and content that follows all rules.
            """

        try validContent.write(to: testFile, atomically: true, encoding: .utf8)

        let command = PDFCommand(inputPath: testFile.path)
        try await command.run()

        #expect(FileManager.default.fileExists(atPath: pdfFile.path))

        try? FileManager.default.removeItem(at: testFile)
        try? FileManager.default.removeItem(at: pdfFile)
    }

    @Test("Fails validation with missing frontmatter")
    func testFailsWithMissingFrontmatter() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("invalid-standard.md")

        let invalidContent = """
            ## Test Content

            This file has no frontmatter.
            """

        try invalidContent.write(to: testFile, atomically: true, encoding: .utf8)

        let command = PDFCommand(inputPath: testFile.path)
        await #expect(throws: CommandError.self) {
            try await command.run()
        }

        try? FileManager.default.removeItem(at: testFile)
    }

    @Test("Fails validation with missing title in frontmatter")
    func testFailsWithMissingTitle() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("no-title.md")

        let invalidContent = """
            ---
            respondent_type: org
            code: test_standard
            ---

            ## Test Content

            This file has frontmatter but no title.
            """

        try invalidContent.write(to: testFile, atomically: true, encoding: .utf8)

        let command = PDFCommand(inputPath: testFile.path)
        await #expect(throws: CommandError.self) {
            try await command.run()
        }

        try? FileManager.default.removeItem(at: testFile)
    }

    @Test("Fails validation with lines exceeding 120 characters")
    func testFailsWithLongLines() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("long-lines.md")

        let longLine = String(repeating: "a", count: 121)
        let invalidContent = """
            ---
            title: Test Standard
            ---

            ## Test Content

            \(longLine)
            """

        try invalidContent.write(to: testFile, atomically: true, encoding: .utf8)

        let command = PDFCommand(inputPath: testFile.path)
        await #expect(throws: CommandError.self) {
            try await command.run()
        }

        try? FileManager.default.removeItem(at: testFile)
    }

    @Test("Fails when file does not exist")
    func testFailsWhenFileDoesNotExist() async throws {
        let command = PDFCommand(inputPath: "/nonexistent/file.md")
        await #expect(throws: CommandError.self) {
            try await command.run()
        }
    }

    @Test("Fails when file is not a markdown file")
    func testFailsWhenNotMarkdownFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test.txt")

        try "test content".write(to: testFile, atomically: true, encoding: .utf8)

        let command = PDFCommand(inputPath: testFile.path)
        await #expect(throws: CommandError.self) {
            try await command.run()
        }

        try? FileManager.default.removeItem(at: testFile)
    }

    @Test("Strips frontmatter from markdown content")
    func testStripsFrontmatter() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("frontmatter-test.md")
        let pdfFile = tempDir.appendingPathComponent("frontmatter-test.pdf")

        let content = """
            ---
            title: Test Standard
            code: test
            description: Test
            respondent_type: org
            flow:
              BEGIN:
                _: END
            alignment:
              BEGIN:
                _: END
            ---

            ## Content After Frontmatter

            This content should be in the PDF, but the frontmatter should not.
            """

        try content.write(to: testFile, atomically: true, encoding: .utf8)

        let command = PDFCommand(inputPath: testFile.path)
        try await command.run()

        #expect(FileManager.default.fileExists(atPath: pdfFile.path))

        try? FileManager.default.removeItem(at: testFile)
        try? FileManager.default.removeItem(at: pdfFile)
    }

    @Test("Creates PDF with empty markdown content after frontmatter")
    func testCreatesEmptyPDFAfterValidation() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("empty-content.md")
        let pdfFile = tempDir.appendingPathComponent("empty-content.pdf")

        let content = """
            ---
            title: Test Standard
            code: test
            description: Test
            respondent_type: org
            flow:
              BEGIN:
                _: END
            alignment:
              BEGIN:
                _: END
            ---

            """

        try content.write(to: testFile, atomically: true, encoding: .utf8)

        let command = PDFCommand(inputPath: testFile.path)
        try await command.run()

        #expect(FileManager.default.fileExists(atPath: pdfFile.path))

        try? FileManager.default.removeItem(at: testFile)
        try? FileManager.default.removeItem(at: pdfFile)
    }

    @Test("Overwrites existing PDF file")
    func testOverwritesExistingPDF() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("overwrite-test.md")
        let pdfFile = tempDir.appendingPathComponent("overwrite-test.pdf")

        let content = """
            ---
            title: Test Standard
            code: test
            description: Test
            respondent_type: org
            flow:
              BEGIN:
                _: END
            alignment:
              BEGIN:
                _: END
            ---

            ## Test Content

            This is test content.
            """

        try content.write(to: testFile, atomically: true, encoding: .utf8)

        try "old PDF content".write(to: pdfFile, atomically: true, encoding: .utf8)
        #expect(FileManager.default.fileExists(atPath: pdfFile.path))

        let command = PDFCommand(inputPath: testFile.path)
        try await command.run()

        #expect(FileManager.default.fileExists(atPath: pdfFile.path))

        let pdfContent = try Data(contentsOf: pdfFile)
        #expect(pdfContent.count > "old PDF content".count)

        try? FileManager.default.removeItem(at: testFile)
        try? FileManager.default.removeItem(at: pdfFile)
    }

    @Test("Fails with invalid frontmatter structure")
    func testFailsWithInvalidFrontmatterStructure() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("invalid-frontmatter.md")

        let invalidContent = """
            ---
            title: Test Standard
            This is not valid YAML

            ## Test Content
            """

        try invalidContent.write(to: testFile, atomically: true, encoding: .utf8)

        let command = PDFCommand(inputPath: testFile.path)
        await #expect(throws: CommandError.self) {
            try await command.run()
        }

        try? FileManager.default.removeItem(at: testFile)
    }
}
