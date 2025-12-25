import Foundation
import Testing

@testable import StandardsCLI

@Suite("Violation Model")
struct ViolationTests {
    @Test("Violation with all fields")
    func violationWithAllFields() {
        let violation = Violation(
            ruleCode: "S101",
            message: "Line exceeds maximum length",
            line: 42,
            context: ["length": "150", "max": "120"]
        )

        #expect(violation.ruleCode == "S101")
        #expect(violation.message == "Line exceeds maximum length")
        #expect(violation.line == 42)
        #expect(violation.context?["length"] == "150")
        #expect(violation.context?["max"] == "120")
    }

    @Test("Violation with minimal fields")
    func violationWithMinimalFields() {
        let violation = Violation(
            ruleCode: "F101",
            message: "Missing title"
        )

        #expect(violation.ruleCode == "F101")
        #expect(violation.message == "Missing title")
        #expect(violation.line == nil)
        #expect(violation.context == nil)
    }

    @Test("Violations are equatable")
    func violationsAreEquatable() {
        let violation1 = Violation(ruleCode: "S101", message: "Test", line: 1)
        let violation2 = Violation(ruleCode: "S101", message: "Test", line: 1)
        let violation3 = Violation(ruleCode: "S101", message: "Test", line: 2)

        #expect(violation1 == violation2)
        #expect(violation1 != violation3)
    }
}

@Suite("FileViolations Model")
struct FileViolationsTests {
    @Test("FileViolations with violations is invalid")
    func fileViolationsWithViolationsIsInvalid() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.md")
        let violations = [
            Violation(ruleCode: "S101", message: "Test")
        ]
        let fileViolations = FileViolations(file: fileURL, violations: violations)

        #expect(!fileViolations.isValid)
        #expect(fileViolations.violations.count == 1)
    }

    @Test("FileViolations with no violations is valid")
    func fileViolationsWithNoViolationsIsValid() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.md")
        let fileViolations = FileViolations(file: fileURL, violations: [])

        #expect(fileViolations.isValid)
        #expect(fileViolations.violations.isEmpty)
    }
}

@Suite("LintResult Model")
struct LintResultTests {
    @Test("LintResult with no violations is valid")
    func lintResultWithNoViolationsIsValid() {
        let result = LintResult(fileViolations: [])

        #expect(result.isValid)
        #expect(result.totalViolationCount == 0)
    }

    @Test("LintResult with violations is invalid")
    func lintResultWithViolationsIsInvalid() {
        let file1 = URL(fileURLWithPath: "/tmp/test1.md")
        let file2 = URL(fileURLWithPath: "/tmp/test2.md")

        let fileViolations = [
            FileViolations(
                file: file1,
                violations: [
                    Violation(ruleCode: "S101", message: "Test 1"),
                    Violation(ruleCode: "F101", message: "Test 2"),
                ]
            ),
            FileViolations(
                file: file2,
                violations: [
                    Violation(ruleCode: "S101", message: "Test 3")
                ]
            ),
        ]

        let result = LintResult(fileViolations: fileViolations)

        #expect(!result.isValid)
        #expect(result.totalViolationCount == 3)
        #expect(result.fileViolations.count == 2)
    }

    @Test("LintResult counts violations correctly across multiple files")
    func lintResultCountsViolationsCorrectly() {
        let file1 = URL(fileURLWithPath: "/tmp/test1.md")
        let file2 = URL(fileURLWithPath: "/tmp/test2.md")
        let file3 = URL(fileURLWithPath: "/tmp/test3.md")

        let fileViolations = [
            FileViolations(
                file: file1,
                violations: [
                    Violation(ruleCode: "S101", message: "Test")
                ]
            ),
            FileViolations(file: file2, violations: []),
            FileViolations(
                file: file3,
                violations: [
                    Violation(ruleCode: "F101", message: "Test"),
                    Violation(ruleCode: "F102", message: "Test"),
                ]
            ),
        ]

        let result = LintResult(fileViolations: fileViolations)

        #expect(result.totalViolationCount == 3)
    }
}
