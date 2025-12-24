import Fluent
import Foundation
import StandardsDAL
import Testing
import Vapor

@Suite("Notation and AssignedNotation Tests")
struct NotationTests {

    @Test("Create notation with version (commit SHA)")
    func testCreateNotationWithVersion() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let commitSHA = "abc123def456789012345678901234567890abcd"

            let notation = Notation()
            notation.title = "Test Notation"
            notation.description = "A test notation"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = commitSHA
            notation.$owner.id = ownerID

            try await notation.save(on: db)
            let notationID = try notation.requireID()

            let fetched = try await Notation.find(notationID, on: db)
            #expect(fetched?.version == commitSHA, "Version should match commit SHA")
        }
    }

    @Test("Notation version field stores full git commit SHA")
    func testNotationVersionStoresFullCommitSHA() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Full 40-character git SHA-1 hash
            let fullCommitSHA = "0123456789abcdef0123456789abcdef01234567"

            let notation = Notation()
            notation.title = "Versioned Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Content"
            notation.frontmatter = [:]
            notation.version = fullCommitSHA
            notation.$owner.id = ownerID

            try await notation.save(on: db)

            let fetched = try await Notation.find(notation.id, on: db)
            #expect(fetched?.version == fullCommitSHA, "Should store full 40-character SHA")
            #expect(fetched?.version.count == 40, "SHA should be 40 characters")
        }
    }

    @Test("Create notation with person respondent type")
    func testCreateNotationForPerson() async throws {
        try await TestUtilities.withApp { app, db in
            // Create owner entity
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let notation = Notation()
            notation.title = "Person Notation"
            notation.description = "A notation for a person"
            notation.respondentType = .person
            notation.markdownContent = "# Sample Markdown\n\nThis is a test."
            notation.frontmatter = ["author": "Test", "date": "2024-01-01"]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID

            try await notation.save(on: db)
            let notationID = try notation.requireID()
            #expect(notationID > 0, "Notation should be created with valid ID")

            let fetched = try await Notation.find(notationID, on: db)
            #expect(fetched != nil, "Notation should be retrievable")
            #expect(fetched?.respondentType == .person, "Respondent type should be person")
            #expect(fetched?.title == "Person Notation", "Title should match")
            #expect(
                fetched?.markdownContent == "# Sample Markdown\n\nThis is a test.",
                "Markdown should match"
            )
            #expect(
                fetched?.frontmatter["author"] == "Test",
                "Frontmatter should be stored correctly"
            )
            #expect(fetched?.$owner.id == ownerID, "Owner ID should match")
        }
    }

    @Test("Create notation with entity respondent type")
    func testCreateNotationForEntity() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let notation = Notation()
            notation.title = "Entity Notation"
            notation.description = "A notation for an entity"
            notation.respondentType = .entity
            notation.markdownContent = "# Entity Document"
            notation.frontmatter = ["type": "corporate"]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID

            try await notation.save(on: db)
            let notationID = try notation.requireID()
            #expect(notationID > 0, "Notation should be created with valid ID")

            let fetched = try await Notation.find(notationID, on: db)
            #expect(fetched?.respondentType == .entity, "Respondent type should be entity")
        }
    }

    @Test("Create notation with person_and_entity respondent type")
    func testCreateNotationForPersonAndEntity() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let notation = Notation()
            notation.title = "Combined Notation"
            notation.description = "A notation for both person and entity"
            notation.respondentType = .personAndEntity
            notation.markdownContent = "# Combined Document"
            notation.frontmatter = ["category": "hybrid"]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID

            try await notation.save(on: db)
            let notationID = try notation.requireID()
            #expect(notationID > 0, "Notation should be created with valid ID")

            let fetched = try await Notation.find(notationID, on: db)
            #expect(
                fetched?.respondentType == .personAndEntity,
                "Respondent type should be person_and_entity"
            )
        }
    }

    @Test("Assign notation to person - valid assignment")
    func testAssignNotationToPersonValid() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create person
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            // Create notation for person type
            let notation = Notation()
            notation.title = "Person Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            // Create assigned notation
            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = nil
            assigned.state = .open

            // Validate before saving
            try await assigned.validate(on: db)
            try await assigned.save(on: db)

            let assignedID = try assigned.requireID()
            #expect(assignedID > 0, "AssignedNotation should be created")

            let fetched = try await AssignedNotation.find(assignedID, on: db)
            #expect(fetched?.$person.id == personID, "Person ID should match")
            #expect(fetched?.$entity.id == nil, "Entity ID should be nil")
            #expect(fetched?.state == .open, "State should be open")
        }
    }

    @Test("Assign notation to person - invalid with entity_id set")
    func testAssignNotationToPersonInvalidWithEntity() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create person and entity
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let jurisdiction = TestUtilities.createTestJurisdiction()
            try await jurisdiction.save(on: db)
            let jurisdictionID = try jurisdiction.requireID()

            let entityType = TestUtilities.createTestEntityType(jurisdictionID: jurisdictionID)
            try await entityType.save(on: db)
            let entityTypeID = try entityType.requireID()

            let entity = TestUtilities.createTestEntity(legalEntityTypeID: entityTypeID)
            try await entity.save(on: db)
            let entityID = try entity.requireID()

            // Create notation for person type
            let notation = Notation()
            notation.title = "Person Only"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            // Try to create invalid assigned notation
            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = entityID  // This should be nil!
            assigned.state = .open

            // Validation should fail
            await #expect(throws: Abort.self) {
                try await assigned.validate(on: db)
            }
        }
    }

    @Test("Assign notation to entity - valid assignment")
    func testAssignNotationToEntityValid() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create entity
            let jurisdiction = TestUtilities.createTestJurisdiction()
            try await jurisdiction.save(on: db)
            let jurisdictionID = try jurisdiction.requireID()

            let entityType = TestUtilities.createTestEntityType(jurisdictionID: jurisdictionID)
            try await entityType.save(on: db)
            let entityTypeID = try entityType.requireID()

            let entity = TestUtilities.createTestEntity(legalEntityTypeID: entityTypeID)
            try await entity.save(on: db)
            let entityID = try entity.requireID()

            // Create notation for entity type
            let notation = Notation()
            notation.title = "Entity Notation"
            notation.description = "Test"
            notation.respondentType = .entity
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            // Create assigned notation
            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = nil
            assigned.$entity.id = entityID
            assigned.state = .open

            try await assigned.validate(on: db)
            try await assigned.save(on: db)

            let assignedID = try assigned.requireID()
            #expect(assignedID > 0, "AssignedNotation should be created")

            let fetched = try await AssignedNotation.find(assignedID, on: db)
            #expect(fetched?.$person.id == nil, "Person ID should be nil")
            #expect(fetched?.$entity.id == entityID, "Entity ID should match")
        }
    }

    @Test("Assign notation to entity - invalid with person_id set")
    func testAssignNotationToEntityInvalidWithPerson() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create person and entity
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let jurisdiction = TestUtilities.createTestJurisdiction()
            try await jurisdiction.save(on: db)
            let jurisdictionID = try jurisdiction.requireID()

            let entityType = TestUtilities.createTestEntityType(jurisdictionID: jurisdictionID)
            try await entityType.save(on: db)
            let entityTypeID = try entityType.requireID()

            let entity = TestUtilities.createTestEntity(legalEntityTypeID: entityTypeID)
            try await entity.save(on: db)
            let entityID = try entity.requireID()

            // Create notation for entity type
            let notation = Notation()
            notation.title = "Entity Only"
            notation.description = "Test"
            notation.respondentType = .entity
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            // Try to create invalid assigned notation
            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID  // This should be nil!
            assigned.$entity.id = entityID
            assigned.state = .open

            // Validation should fail
            await #expect(throws: Abort.self) {
                try await assigned.validate(on: db)
            }
        }
    }

    @Test("Assign notation to person and entity - valid assignment")
    func testAssignNotationToPersonAndEntityValid() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create person and entity
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let jurisdiction = TestUtilities.createTestJurisdiction()
            try await jurisdiction.save(on: db)
            let jurisdictionID = try jurisdiction.requireID()

            let entityType = TestUtilities.createTestEntityType(jurisdictionID: jurisdictionID)
            try await entityType.save(on: db)
            let entityTypeID = try entityType.requireID()

            let entity = TestUtilities.createTestEntity(legalEntityTypeID: entityTypeID)
            try await entity.save(on: db)
            let entityID = try entity.requireID()

            // Create notation for person_and_entity type
            let notation = Notation()
            notation.title = "Combined Notation"
            notation.description = "Test"
            notation.respondentType = .personAndEntity
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            // Create assigned notation
            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = entityID
            assigned.state = .open

            try await assigned.validate(on: db)
            try await assigned.save(on: db)

            let assignedID = try assigned.requireID()
            #expect(assignedID > 0, "AssignedNotation should be created")

            let fetched = try await AssignedNotation.find(assignedID, on: db)
            #expect(fetched?.$person.id == personID, "Person ID should match")
            #expect(fetched?.$entity.id == entityID, "Entity ID should match")
        }
    }

    @Test("Assign notation to person and entity - invalid without person_id")
    func testAssignNotationToPersonAndEntityInvalidWithoutPerson() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create entity
            let jurisdiction = TestUtilities.createTestJurisdiction()
            try await jurisdiction.save(on: db)
            let jurisdictionID = try jurisdiction.requireID()

            let entityType = TestUtilities.createTestEntityType(jurisdictionID: jurisdictionID)
            try await entityType.save(on: db)
            let entityTypeID = try entityType.requireID()

            let entity = TestUtilities.createTestEntity(legalEntityTypeID: entityTypeID)
            try await entity.save(on: db)
            let entityID = try entity.requireID()

            // Create notation for person_and_entity type
            let notation = Notation()
            notation.title = "Combined Notation"
            notation.description = "Test"
            notation.respondentType = .personAndEntity
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            // Try to create invalid assigned notation (missing person_id)
            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = nil  // This should be set!
            assigned.$entity.id = entityID
            assigned.state = .open

            // Validation should fail
            await #expect(throws: Abort.self) {
                try await assigned.validate(on: db)
            }
        }
    }

    @Test("Assign notation to person and entity - invalid without entity_id")
    func testAssignNotationToPersonAndEntityInvalidWithoutEntity() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create person
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            // Create notation for person_and_entity type
            let notation = Notation()
            notation.title = "Combined Notation"
            notation.description = "Test"
            notation.respondentType = .personAndEntity
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            // Try to create invalid assigned notation (missing entity_id)
            let assigned = AssignedNotation()
            assigned.$notation.id = notationID
            assigned.$person.id = personID
            assigned.$entity.id = nil  // This should be set!
            assigned.state = .open

            // Validation should fail
            await #expect(throws: Abort.self) {
                try await assigned.validate(on: db)
            }
        }
    }

    @Test("Prevent duplicate open assignments")
    func testPreventDuplicateOpenAssignments() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create person
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            // Create notation
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
            try await assigned1.validate(on: db)
            try await assigned1.save(on: db)

            // Check for active assignment
            let hasActive = try await AssignedNotation.hasActiveAssignment(
                notationID: notationID,
                personID: personID,
                entityID: nil,
                on: db
            )
            #expect(hasActive == true, "Should find active assignment")

            // Try to create duplicate open assignment - should be prevented by database constraint
            let assigned2 = AssignedNotation()
            assigned2.$notation.id = notationID
            assigned2.$person.id = personID
            assigned2.$entity.id = nil
            assigned2.state = .open

            // Database constraint should prevent this
            await #expect(throws: Error.self) {
                try await assigned2.save(on: db)
            }
        }
    }

    @Test("Allow duplicate assignments when first is closed")
    func testAllowDuplicateWhenFirstIsClosed() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create person
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            // Create notation
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

            // Create first assignment and close it
            let assigned1 = AssignedNotation()
            assigned1.$notation.id = notationID
            assigned1.$person.id = personID
            assigned1.$entity.id = nil
            assigned1.state = .closed  // Closed state
            try await assigned1.validate(on: db)
            try await assigned1.save(on: db)

            // Check for active assignment - should be false
            let hasActive = try await AssignedNotation.hasActiveAssignment(
                notationID: notationID,
                personID: personID,
                entityID: nil,
                on: db
            )
            #expect(hasActive == false, "Should not find active assignment")

            // Create second assignment - should succeed
            let assigned2 = AssignedNotation()
            assigned2.$notation.id = notationID
            assigned2.$person.id = personID
            assigned2.$entity.id = nil
            assigned2.state = .open
            try await assigned2.validate(on: db)
            try await assigned2.save(on: db)

            let assignedID2 = try assigned2.requireID()
            #expect(assignedID2 > 0, "Second assignment should be created")
        }
    }

    @Test("Close assignment and create new open assignment")
    func testCloseAndReopenAssignment() async throws {
        try await TestUtilities.withApp { app, db in
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            // Create person
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            // Create notation
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
            try await assigned1.validate(on: db)
            try await assigned1.save(on: db)
            let assignedID1 = try assigned1.requireID()

            // Close the first assignment
            assigned1.state = .closed
            try await assigned1.update(on: db)

            // Verify it's closed
            let fetched1 = try await AssignedNotation.find(assignedID1, on: db)
            #expect(fetched1?.state == .closed, "First assignment should be closed")

            // Create new open assignment - should succeed
            let assigned2 = AssignedNotation()
            assigned2.$notation.id = notationID
            assigned2.$person.id = personID
            assigned2.$entity.id = nil
            assigned2.state = .open
            try await assigned2.validate(on: db)
            try await assigned2.save(on: db)

            let assignedID2 = try assigned2.requireID()
            #expect(assignedID2 > 0, "Second assignment should be created")
            #expect(assignedID2 != assignedID1, "Should be different assignments")
        }
    }
}
