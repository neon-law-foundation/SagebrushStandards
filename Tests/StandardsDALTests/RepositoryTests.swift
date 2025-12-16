import Fluent
import Foundation
import StandardsDAL
import Testing
import Vapor

@Suite("Repository Tests")
struct RepositoryTests {

    @Test("PersonRepository - CRUD operations")
    func testPersonRepository() async throws {
        try await TestUtilities.withApp { app, db in
            let repo = PersonRepository(database: db)

            // Create
            let person = TestUtilities.createTestPerson(name: "Jane Doe", email: "jane@example.com")
            let created = try await repo.create(model: person)
            #expect(created.id != nil, "Created person should have an ID")

            // Find
            let found = try await repo.find(id: created.id!)
            #expect(found != nil, "Should find created person")
            #expect(found?.name == "Jane Doe", "Person name should match")

            // Find by email
            let foundByEmail = try await repo.findByEmail("jane@example.com")
            #expect(foundByEmail != nil, "Should find person by email")
            #expect(foundByEmail?.id == created.id, "Found person should match created")

            // Update
            created.name = "Jane Smith"
            let updated = try await repo.update(model: created)
            #expect(updated.name == "Jane Smith", "Person name should be updated")

            // Find all
            let all = try await repo.findAll()
            #expect(all.count > 0, "Should have at least one person")

            // Delete
            try await repo.delete(id: created.id!)
            let deleted = try await repo.find(id: created.id!)
            #expect(deleted == nil, "Person should be deleted")
        }
    }

    @Test("JurisdictionRepository - CRUD operations")
    func testJurisdictionRepository() async throws {
        try await TestUtilities.withApp { app, db in
            let repo = JurisdictionRepository(database: db)

            // Create
            let jurisdiction = TestUtilities.createTestJurisdiction(name: "Texas", code: "TX", type: .state)
            let created = try await repo.create(model: jurisdiction)
            #expect(created.id != nil, "Created jurisdiction should have an ID")

            // Find
            let found = try await repo.find(id: created.id!)
            #expect(found != nil, "Should find created jurisdiction")

            // Find by code
            let foundByCode = try await repo.findByCode("TX")
            #expect(foundByCode != nil, "Should find jurisdiction by code")
            #expect(foundByCode?.name == "Texas", "Jurisdiction name should match")

            // Delete
            try await repo.delete(id: created.id!)
            let deleted = try await repo.find(id: created.id!)
            #expect(deleted == nil, "Jurisdiction should be deleted")
        }
    }

    @Test("ProjectRepository - CRUD operations")
    func testProjectRepository() async throws {
        try await TestUtilities.withApp { app, db in
            let repo = ProjectRepository(database: db)

            // Create
            let project = TestUtilities.createTestProject(codename: "ALPHA2024")
            let created = try await repo.create(model: project)
            #expect(created.id != nil, "Created project should have an ID")

            // Find by codename
            let foundByCodename = try await repo.findByCodename("ALPHA2024")
            #expect(foundByCodename != nil, "Should find project by codename")
            #expect(foundByCodename?.id == created.id, "Found project should match created")

            // Delete
            try await repo.delete(id: created.id!)
            let deleted = try await repo.find(id: created.id!)
            #expect(deleted == nil, "Project should be deleted")
        }
    }

    @Test("QuestionRepository - CRUD and type filtering")
    func testQuestionRepository() async throws {
        try await TestUtilities.withApp { app, db in
            let repo = QuestionRepository(database: db)

            // Create multiple questions
            let question1 = Question(
                prompt: "What is your name?",
                questionType: .string,
                code: "NAME"
            )
            let question2 = Question(
                prompt: "What is your date of birth?",
                questionType: .date,
                code: "DOB"
            )
            let question3 = Question(
                prompt: "What is your email?",
                questionType: .email,
                code: "EMAIL"
            )

            _ = try await repo.create(model: question1)
            _ = try await repo.create(model: question2)
            _ = try await repo.create(model: question3)

            // Find by code
            let foundByCode = try await repo.findByCode("NAME")
            #expect(foundByCode != nil, "Should find question by code")
            #expect(foundByCode?.questionType == .string, "Question type should match")

            // Find by type
            let stringQuestions = try await repo.findByType(.string)
            #expect(stringQuestions.count >= 1, "Should find at least one string question")

            // Find all
            let all = try await repo.findAll()
            #expect(all.count >= 3, "Should have at least 3 questions")
        }
    }

    @Test("AddressRepository - Person and Entity addresses")
    func testAddressRepository() async throws {
        try await TestUtilities.withApp { app, db in
            let addressRepo = AddressRepository(database: db)
            let personRepo = PersonRepository(database: db)

            // Create a person
            let person = TestUtilities.createTestPerson()
            let createdPerson = try await personRepo.create(model: person)
            let personID = try createdPerson.requireID()

            // Create address for person
            let personAddress = TestUtilities.createTestAddressForPerson(
                personID: personID,
                city: "Austin"
            )
            let createdAddress = try await addressRepo.create(model: personAddress)
            #expect(createdAddress.id != nil, "Created address should have an ID")

            // Find addresses by person
            let personAddresses = try await addressRepo.findByPerson(personId: personID)
            #expect(personAddresses.count == 1, "Should find one address for person")
            #expect(personAddresses.first?.city == "Austin", "Address city should match")
        }
    }

    @Test("CredentialRepository - Person and Jurisdiction relationships")
    func testCredentialRepository() async throws {
        try await TestUtilities.withApp { app, db in
            let credentialRepo = CredentialRepository(database: db)
            let personRepo = PersonRepository(database: db)
            let jurisdictionRepo = JurisdictionRepository(database: db)

            // Create person and jurisdiction
            let person = TestUtilities.createTestPerson()
            let createdPerson = try await personRepo.create(model: person)
            let personID = try createdPerson.requireID()

            let jurisdiction = TestUtilities.createTestJurisdiction()
            let createdJurisdiction = try await jurisdictionRepo.create(model: jurisdiction)
            let jurisdictionID = try createdJurisdiction.requireID()

            // Create credential
            let credential = TestUtilities.createTestCredential(
                personID: personID,
                jurisdictionID: jurisdictionID,
                licenseNumber: "BAR123"
            )
            let createdCredential = try await credentialRepo.create(model: credential)
            #expect(createdCredential.id != nil, "Created credential should have an ID")

            // Find by person
            let personCredentials = try await credentialRepo.findByPerson(personId: personID)
            #expect(personCredentials.count == 1, "Should find one credential for person")

            // Find by jurisdiction
            let jurisdictionCredentials = try await credentialRepo.findByJurisdiction(
                jurisdictionId: jurisdictionID
            )
            #expect(jurisdictionCredentials.count == 1, "Should find one credential for jurisdiction")
        }
    }
}
