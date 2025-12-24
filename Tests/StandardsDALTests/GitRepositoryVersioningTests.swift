import Fluent
import Foundation
import StandardsDAL
import Testing
import Vapor

@Suite("Git Repository Versioning Tests")
struct GitRepositoryVersioningTests {

    // MARK: - GitRepository Model Tests

    @Test("Create git repository with AWS metadata")
    func testCreateGitRepository() async throws {
        try await TestUtilities.withApp { app, db in
            let repo = GitRepository(
                awsAccountID: "889786867297",
                awsRegion: "us-west-2",
                codecommitRepositoryID: "abc-123-def-456",
                repositoryName: "legal-templates",
                repositoryARN: "arn:aws:codecommit:us-west-2:889786867297:legal-templates"
            )

            try await repo.save(on: db)
            let repoID = try repo.requireID()

            let fetched = try await GitRepository.find(repoID, on: db)
            #expect(fetched?.awsAccountID == "889786867297")
            #expect(fetched?.awsRegion == "us-west-2")
            #expect(fetched?.repositoryName == "legal-templates")
            #expect(fetched?.codecommitRepositoryID == "abc-123-def-456")
        }
    }

    @Test("Git repository unique constraint prevents duplicates")
    func testGitRepositoryUniqueConstraint() async throws {
        try await TestUtilities.withApp { app, db in
            let repo1 = GitRepository(
                awsAccountID: "123456789012",
                awsRegion: "us-west-2",
                codecommitRepositoryID: "abc-123-def",
                repositoryName: "standards",
                repositoryARN: "arn:aws:codecommit:us-west-2:123456789012:standards"
            )
            try await repo1.save(on: db)

            let repo2 = GitRepository(
                awsAccountID: "123456789012",
                awsRegion: "us-west-2",
                codecommitRepositoryID: "abc-123-def",
                repositoryName: "standards-copy",
                repositoryARN: "arn:aws:codecommit:us-west-2:123456789012:standards-copy"
            )

            await #expect(throws: Error.self) {
                try await repo2.save(on: db)
            }
        }
    }

    // MARK: - Notation with Git Repository Tests

    @Test("Create notation with git repository reference")
    func testCreateNotationWithGitRepository() async throws {
        try await TestUtilities.withApp { app, db in
            let repoID = try await createTestRepository(on: db)
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let notation = Notation()
            notation.$gitRepository.id = repoID
            notation.code = "france-contractor-agreement"
            notation.version = "abc123def456789012345678901234567890abcd"
            notation.title = "France Contractor Agreement"
            notation.description = "Standard contractor agreement for France"
            notation.respondentType = .person
            notation.markdownContent = "# Agreement"
            notation.frontmatter = [:]
            notation.$owner.id = ownerID

            try await notation.save(on: db)

            let fetched = try await Notation.find(notation.id, on: db)
            #expect(fetched?.$gitRepository.id == repoID)
            #expect(fetched?.code == "france-contractor-agreement")
        }
    }

    @Test("Notation unique version constraint per repository")
    func testNotationUniqueVersionPerRepository() async throws {
        try await TestUtilities.withApp { app, db in
            let repoID = try await createTestRepository(on: db)
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)

            let notation1 = Notation()
            notation1.$gitRepository.id = repoID
            notation1.code = "test-notation"
            notation1.version = "abc123"
            notation1.title = "Test"
            notation1.description = "Test"
            notation1.respondentType = .person
            notation1.markdownContent = "# Test"
            notation1.frontmatter = [:]
            notation1.$owner.id = ownerID
            try await notation1.save(on: db)

            let notation2 = Notation()
            notation2.$gitRepository.id = repoID
            notation2.code = "test-notation"
            notation2.version = "abc123"
            notation2.title = "Test 2"
            notation2.description = "Test 2"
            notation2.respondentType = .person
            notation2.markdownContent = "# Test 2"
            notation2.frontmatter = [:]
            notation2.$owner.id = ownerID

            await #expect(throws: Error.self) {
                try await notation2.save(on: db)
            }
        }
    }

    // MARK: - NotationService Tests

    @Test("NotationService finds latest version by inserted_at")
    func testNotationServiceFindsLatestVersion() async throws {
        try await TestUtilities.withApp { app, db in
            let repoID = try await createTestRepository(on: db)
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)
            let service = NotationService(database: db)

            let v1 = Notation()
            v1.$gitRepository.id = repoID
            v1.code = "coi-disclosure"
            v1.version = "abc123"
            v1.title = "COI Disclosure v1"
            v1.description = "Version 1"
            v1.respondentType = .person
            v1.markdownContent = "# Version 1"
            v1.frontmatter = [:]
            v1.$owner.id = ownerID
            try await v1.save(on: db)

            try await Task.sleep(nanoseconds: 100_000_000)

            let v2 = Notation()
            v2.$gitRepository.id = repoID
            v2.code = "coi-disclosure"
            v2.version = "def456"
            v2.title = "COI Disclosure v2"
            v2.description = "Version 2"
            v2.respondentType = .person
            v2.markdownContent = "# Version 2"
            v2.frontmatter = [:]
            v2.$owner.id = ownerID
            try await v2.save(on: db)

            let latest = try await service.findLatestVersion(
                gitRepositoryID: repoID,
                code: "coi-disclosure"
            )
            #expect(latest?.version == "def456", "Should return newest version")
        }
    }

    @Test("NotationService finds all versions ordered by recency")
    func testNotationServiceFindsAllVersions() async throws {
        try await TestUtilities.withApp { app, db in
            let repoID = try await createTestRepository(on: db)
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)
            let service = NotationService(database: db)

            for i in 1...3 {
                let notation = Notation()
                notation.$gitRepository.id = repoID
                notation.code = "bylaws"
                notation.version = String(format: "%040d", i)
                notation.title = "Bylaws v\(i)"
                notation.description = "Version \(i)"
                notation.respondentType = .entity
                notation.markdownContent = "# V\(i)"
                notation.frontmatter = [:]
                notation.$owner.id = ownerID
                try await notation.save(on: db)

                try await Task.sleep(nanoseconds: 50_000_000)
            }

            let allVersions = try await service.findAllVersions(
                gitRepositoryID: repoID,
                code: "bylaws"
            )
            #expect(allVersions.count == 3)
            #expect(allVersions[0].version == String(format: "%040d", 3))
            #expect(allVersions[1].version == String(format: "%040d", 2))
            #expect(allVersions[2].version == String(format: "%040d", 1))
        }
    }

    @Test("NotationService createVersion prevents duplicate versions")
    func testNotationServicePreventsDuplicateVersions() async throws {
        try await TestUtilities.withApp { app, db in
            let repoID = try await createTestRepository(on: db)
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)
            let service = NotationService(database: db)

            try await service.createVersion(
                gitRepositoryID: repoID,
                code: "test-notation",
                version: "abc123",
                title: "Test",
                description: "Test",
                respondentType: .person,
                markdownContent: "# Test",
                frontmatter: [:],
                ownerID: ownerID
            )

            await #expect(throws: NotationError.self) {
                try await service.createVersion(
                    gitRepositoryID: repoID,
                    code: "test-notation",
                    version: "abc123",
                    title: "Test 2",
                    description: "Test 2",
                    respondentType: .person,
                    markdownContent: "# Test 2",
                    frontmatter: [:],
                    ownerID: ownerID
                )
            }
        }
    }

    // MARK: - AssignedNotationService Tests

    @Test("AssignedNotationService prevents outdated notation assignment")
    func testAssignedNotationServicePreventsOutdatedAssignment() async throws {
        try await TestUtilities.withApp { app, db in
            let service = AssignedNotationService(database: db)
            let repoID = try await createTestRepository(on: db)
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let v1 = Notation()
            v1.$gitRepository.id = repoID
            v1.code = "coi-disclosure"
            v1.version = "abc123"
            v1.title = "COI Disclosure v1"
            v1.description = "Version 1"
            v1.respondentType = .person
            v1.markdownContent = "# Version 1"
            v1.frontmatter = [:]
            v1.$owner.id = ownerID
            try await v1.save(on: db)
            let v1ID = try v1.requireID()

            try await Task.sleep(nanoseconds: 100_000_000)

            let v2 = Notation()
            v2.$gitRepository.id = repoID
            v2.code = "coi-disclosure"
            v2.version = "def456"
            v2.title = "COI Disclosure v2"
            v2.description = "Version 2"
            v2.respondentType = .person
            v2.markdownContent = "# Version 2"
            v2.frontmatter = [:]
            v2.$owner.id = ownerID
            try await v2.save(on: db)

            await #expect(throws: AssignedNotationError.self) {
                try await service.createAssignment(
                    notationID: v1ID,
                    personID: personID,
                    entityID: nil
                )
            }
        }
    }

    @Test("AssignedNotationService allows assignment of latest version")
    func testAssignedNotationServiceAllowsLatestAssignment() async throws {
        try await TestUtilities.withApp { app, db in
            let service = AssignedNotationService(database: db)
            let repoID = try await createTestRepository(on: db)
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let v1 = Notation()
            v1.$gitRepository.id = repoID
            v1.code = "coi-disclosure"
            v1.version = "abc123"
            v1.title = "COI Disclosure v1"
            v1.description = "Version 1"
            v1.respondentType = .person
            v1.markdownContent = "# Version 1"
            v1.frontmatter = [:]
            v1.$owner.id = ownerID
            try await v1.save(on: db)

            try await Task.sleep(nanoseconds: 100_000_000)

            let v2 = Notation()
            v2.$gitRepository.id = repoID
            v2.code = "coi-disclosure"
            v2.version = "def456"
            v2.title = "COI Disclosure v2"
            v2.description = "Version 2"
            v2.respondentType = .person
            v2.markdownContent = "# Version 2"
            v2.frontmatter = [:]
            v2.$owner.id = ownerID
            try await v2.save(on: db)
            let v2ID = try v2.requireID()

            let assignment = try await service.createAssignment(
                notationID: v2ID,
                personID: personID,
                entityID: nil
            )

            #expect(assignment.id != nil)
            #expect(assignment.$notation.id == v2ID)
        }
    }

    @Test("AssignedNotationService createAssignmentByCode uses latest version")
    func testAssignedNotationServiceCreateByCode() async throws {
        try await TestUtilities.withApp { app, db in
            let service = AssignedNotationService(database: db)
            let repoID = try await createTestRepository(on: db)
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let v1 = Notation()
            v1.$gitRepository.id = repoID
            v1.code = "coi-disclosure"
            v1.version = "abc123"
            v1.title = "COI Disclosure v1"
            v1.description = "Version 1"
            v1.respondentType = .person
            v1.markdownContent = "# Version 1"
            v1.frontmatter = [:]
            v1.$owner.id = ownerID
            try await v1.save(on: db)

            try await Task.sleep(nanoseconds: 100_000_000)

            let v2 = Notation()
            v2.$gitRepository.id = repoID
            v2.code = "coi-disclosure"
            v2.version = "def456"
            v2.title = "COI Disclosure v2"
            v2.description = "Version 2"
            v2.respondentType = .person
            v2.markdownContent = "# Version 2"
            v2.frontmatter = [:]
            v2.$owner.id = ownerID
            try await v2.save(on: db)
            let v2ID = try v2.requireID()

            let assignment = try await service.createAssignmentByCode(
                gitRepositoryID: repoID,
                code: "coi-disclosure",
                personID: personID,
                entityID: nil
            )

            #expect(assignment.$notation.id == v2ID, "Should use latest version (v2)")
        }
    }

    @Test("AssignedNotationService prevents duplicate active assignments")
    func testAssignedNotationServicePreventsDuplicateActiveAssignments() async throws {
        try await TestUtilities.withApp { app, db in
            let service = AssignedNotationService(database: db)
            let repoID = try await createTestRepository(on: db)
            let ownerID = try await TestUtilities.createTestOwnerEntity(on: db)
            let person = TestUtilities.createTestPerson()
            try await person.save(on: db)
            let personID = try person.requireID()

            let notation = Notation()
            notation.$gitRepository.id = repoID
            notation.code = "unique-notation"
            notation.version = "test123"
            notation.title = "Test Notation"
            notation.description = "Test"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            notation.$owner.id = ownerID
            try await notation.save(on: db)
            let notationID = try notation.requireID()

            let first = try await service.createAssignment(
                notationID: notationID,
                personID: personID,
                entityID: nil
            )
            #expect(first.id != nil)

            await #expect(throws: AssignedNotationError.self) {
                try await service.createAssignment(
                    notationID: notationID,
                    personID: personID,
                    entityID: nil
                )
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestRepository(on database: Database) async throws -> Int32 {
        let repo = GitRepository(
            awsAccountID: "889786867297",
            awsRegion: "us-west-2",
            codecommitRepositoryID: UUID().uuidString,
            repositoryName: "test-repo-\(UUID().uuidString.prefix(8))",
            repositoryARN: "arn:aws:codecommit:us-west-2:889786867297:test-repo"
        )
        try await repo.save(on: database)
        return try repo.requireID()
    }
}
