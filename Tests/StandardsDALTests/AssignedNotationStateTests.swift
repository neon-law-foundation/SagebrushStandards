import Fluent
import Foundation
import StandardsDAL
import Testing
import Vapor

@Suite("AssignedNotation State Machine Tests")
struct AssignedNotationStateTests {

    @Test("AssignedNotationState enum contains all expected states")
    func testAllStatesExist() {
        let expectedStates: [AssignedNotationState] = [
            .open,
            .review,
            .waitingForFlow,
            .waitingForAlignment,
            .closed,
        ]

        #expect(AssignedNotationState.allCases.count == expectedStates.count, "Should have exactly 5 states")

        for state in expectedStates {
            #expect(AssignedNotationState.allCases.contains(state), "Should contain \(state)")
        }
    }

    @Test("AssignedNotationState raw values are correct")
    func testRawValues() {
        #expect(AssignedNotationState.open.rawValue == "open")
        #expect(AssignedNotationState.review.rawValue == "review")
        #expect(AssignedNotationState.waitingForFlow.rawValue == "waiting_for_flow")
        #expect(AssignedNotationState.waitingForAlignment.rawValue == "waiting_for_alignment")
        #expect(AssignedNotationState.closed.rawValue == "closed")
    }

    @Test("AssignedNotationState can be decoded from raw values")
    func testDecodeFromRawValue() {
        #expect(AssignedNotationState(rawValue: "open") == .open)
        #expect(AssignedNotationState(rawValue: "review") == .review)
        #expect(AssignedNotationState(rawValue: "waiting_for_flow") == .waitingForFlow)
        #expect(AssignedNotationState(rawValue: "waiting_for_alignment") == .waitingForAlignment)
        #expect(AssignedNotationState(rawValue: "closed") == .closed)
    }

    @Test("Create assignment in open state")
    func testCreateAssignmentInOpenState() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = nil
            assigned.state = .open

            try await assigned.validate(on: db)
            try await assigned.save(on: db)

            let fetched = try await AssignedNotation.find(assigned.id, on: db)
            #expect(fetched?.state == .open, "State should be open")
        }
    }

    @Test("Create assignment in review state")
    func testCreateAssignmentInReviewState() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = nil
            assigned.state = .review

            try await assigned.validate(on: db)
            try await assigned.save(on: db)

            let fetched = try await AssignedNotation.find(assigned.id, on: db)
            #expect(fetched?.state == .review, "State should be review")
        }
    }

    @Test("Create assignment in waiting_for_flow state")
    func testCreateAssignmentInWaitingForFlowState() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = nil
            assigned.state = .waitingForFlow

            try await assigned.validate(on: db)
            try await assigned.save(on: db)

            let fetched = try await AssignedNotation.find(assigned.id, on: db)
            #expect(fetched?.state == .waitingForFlow, "State should be waiting_for_flow")
        }
    }

    @Test("Create assignment in waiting_for_alignment state")
    func testCreateAssignmentInWaitingForAlignmentState() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = nil
            assigned.state = .waitingForAlignment

            try await assigned.validate(on: db)
            try await assigned.save(on: db)

            let fetched = try await AssignedNotation.find(assigned.id, on: db)
            #expect(
                fetched?.state == .waitingForAlignment,
                "State should be waiting_for_alignment"
            )
        }
    }

    @Test("Transition from open to review")
    func testTransitionOpenToReview() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = nil
            assigned.state = .open
            try await assigned.save(on: db)

            // Transition to review
            assigned.state = .review
            try await assigned.update(on: db)

            let fetched = try await AssignedNotation.find(assigned.id, on: db)
            #expect(fetched?.state == .review, "State should transition to review")
        }
    }

    @Test("Transition from review to closed")
    func testTransitionReviewToClosed() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = nil
            assigned.state = .review
            try await assigned.save(on: db)

            // Transition to closed
            assigned.state = .closed
            try await assigned.update(on: db)

            let fetched = try await AssignedNotation.find(assigned.id, on: db)
            #expect(fetched?.state == .closed, "State should transition to closed")
        }
    }

    @Test("Transition from waiting_for_flow to open")
    func testTransitionWaitingForFlowToOpen() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = nil
            assigned.state = .waitingForFlow
            try await assigned.save(on: db)

            // Transition to open
            assigned.state = .open
            try await assigned.update(on: db)

            let fetched = try await AssignedNotation.find(assigned.id, on: db)
            #expect(fetched?.state == .open, "State should transition to open")
        }
    }

    @Test("Prevent duplicate assignments in open state")
    func testPreventDuplicateInOpenState() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            // Create first assignment
            let assigned1 = AssignedNotation()
            assigned1.$notation.id = notationID
            assigned1.$person.id = personID
            assigned1.$entity.id = nil
            assigned1.state = .open
            try await assigned1.save(on: db)

            // Try to create duplicate
            let assigned2 = AssignedNotation()
            assigned2.$notation.id = notationID
            assigned2.$person.id = personID
            assigned2.$entity.id = nil
            assigned2.state = .open

            // Should throw error due to unique constraint
            await #expect(throws: Error.self) {
                try await assigned2.save(on: db)
            }
        }
    }

    @Test("Allow new assignment after closing previous one")
    func testAllowNewAssignmentAfterClosing() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            // Create and close first assignment
            let assigned1 = AssignedNotation()
            assigned1.$notation.id = notationID
            assigned1.$person.id = personID
            assigned1.$entity.id = nil
            assigned1.state = .open
            try await assigned1.save(on: db)

            assigned1.state = .closed
            try await assigned1.update(on: db)

            // Create new assignment - should succeed
            let assigned2 = AssignedNotation()
            assigned2.$notation.id = notationID
            assigned2.$person.id = personID
            assigned2.$entity.id = nil
            assigned2.state = .open
            try await assigned2.save(on: db)

            let fetched = try await AssignedNotation.find(assigned2.id, on: db)
            #expect(fetched?.state == .open, "New assignment should be created")
        }
    }
}
