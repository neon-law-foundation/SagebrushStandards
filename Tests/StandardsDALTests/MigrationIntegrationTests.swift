import Fluent
import FluentSQLiteDriver
import StandardsDAL
import Testing
import Vapor

@Suite("Migration Integration Tests")
struct MigrationIntegrationTests {

    // MARK: - Migration Tests

    @Test("Database migrations run successfully")
    func testMigrationsRunSuccessfully() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // Verify database is configured by querying a table
        // Database configuration is implicit in Vapor

        // Verify all tables exist by querying each model
        let jurisdictionCount = try await Jurisdiction.query(on: app.db).count()
        #expect(jurisdictionCount >= 0)

        let entityTypeCount = try await EntityType.query(on: app.db).count()
        #expect(entityTypeCount >= 0)

        let personCount = try await Person.query(on: app.db).count()
        #expect(personCount >= 0)

        let userCount = try await User.query(on: app.db).count()
        #expect(userCount >= 0)

        let entityCount = try await Entity.query(on: app.db).count()
        #expect(entityCount >= 0)

        let addressCount = try await Address.query(on: app.db).count()
        #expect(addressCount >= 0)

        let mailboxCount = try await Mailbox.query(on: app.db).count()
        #expect(mailboxCount >= 0)

        let credentialCount = try await Credential.query(on: app.db).count()
        #expect(credentialCount >= 0)

        let questionCount = try await Question.query(on: app.db).count()
        #expect(questionCount >= 0)

        let personEntityRoleCount = try await PersonEntityRole.query(on: app.db).count()
        #expect(personEntityRoleCount >= 0)

        try await app.asyncShutdown()
    }

    @Test("Migrations create correct schema")
    func testMigrationsCreateCorrectSchema() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // Create and save a test jurisdiction
        let jurisdiction = Jurisdiction()
        jurisdiction.code = "TEST"
        jurisdiction.name = "Test Jurisdiction"
        jurisdiction.jurisdictionType = .state
        try await jurisdiction.save(on: app.db)

        // Verify it was saved
        let fetched = try await Jurisdiction.query(on: app.db)
            .filter(\.$code == "TEST")
            .first()

        #expect(fetched != nil)
        #expect(fetched?.name == "Test Jurisdiction")
        #expect(fetched?.code == "TEST")
        #expect(fetched?.jurisdictionType == .state)

        try await app.asyncShutdown()
    }

    // MARK: - Seed Loading Tests

    @Test("Seeds load successfully from YAML files")
    func testSeedsLoadSuccessfully() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        let seedCount = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            environment: app.environment,
            logger: app.logger
        )

        // Verify seeds were loaded
        #expect(seedCount > 0)

        // Verify jurisdictions were seeded
        let jurisdictionCount = try await Jurisdiction.query(on: app.db).count()
        #expect(jurisdictionCount > 0)

        // Verify entity types were seeded
        let entityTypeCount = try await EntityType.query(on: app.db).count()
        #expect(entityTypeCount > 0)

        // Verify questions were seeded
        let questionCount = try await Question.query(on: app.db).count()
        #expect(questionCount > 0)

        try await app.asyncShutdown()
    }

    @Test("Seeds load in correct order (foreign key dependencies)")
    func testSeedsLoadInCorrectOrder() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // Run seeds
        _ = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            environment: app.environment,
            logger: app.logger
        )

        // Verify EntityType has valid jurisdiction reference
        let entityTypes = try await EntityType.query(on: app.db).with(\.$jurisdiction).all()

        for entityType in entityTypes {
            // Verify we can load the jurisdiction
            let jurisdiction = try await Jurisdiction.find(entityType.$jurisdiction.id, on: app.db)
            #expect(jurisdiction != nil)
        }

        try await app.asyncShutdown()
    }

    // MARK: - Upsert Behavior Tests

    @Test("Upsert creates new record when not exists")
    func testUpsertCreatesNewRecord() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // Insert a jurisdiction using upsert
        let record: [String: Any] = [
            "name": "California",
            "code": "CA",
            "jurisdiction_type": "state",
        ]

        try await StandardsDALConfiguration.insertJurisdiction(
            record: record,
            lookupFields: ["code"],
            database: app.db
        )

        // Verify it was created
        let jurisdiction = try await Jurisdiction.query(on: app.db)
            .filter(\.$code == "CA")
            .first()

        #expect(jurisdiction != nil)
        #expect(jurisdiction?.name == "California")

        try await app.asyncShutdown()
    }

    @Test("Upsert updates existing record when found")
    func testUpsertUpdatesExistingRecord() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // First insert
        let initialRecord: [String: Any] = [
            "name": "California",
            "code": "CA",
            "jurisdiction_type": "state",
        ]

        try await StandardsDALConfiguration.insertJurisdiction(
            record: initialRecord,
            lookupFields: ["code"],
            database: app.db
        )

        // Second insert with same code but different name (should update)
        let updateRecord: [String: Any] = [
            "name": "State of California",
            "code": "CA",
            "jurisdiction_type": "state",
        ]

        try await StandardsDALConfiguration.insertJurisdiction(
            record: updateRecord,
            lookupFields: ["code"],
            database: app.db
        )

        // Verify only one record exists with updated name
        let jurisdictions = try await Jurisdiction.query(on: app.db)
            .filter(\.$code == "CA")
            .all()

        #expect(jurisdictions.count == 1)
        #expect(jurisdictions.first?.name == "State of California")

        try await app.asyncShutdown()
    }

    @Test("Upsert works with multiple lookup fields")
    func testUpsertWithMultipleLookupFields() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // Create a jurisdiction first
        let jurisdiction = Jurisdiction()
        jurisdiction.code = "CA"
        jurisdiction.name = "California"
        jurisdiction.jurisdictionType = .state
        try await jurisdiction.save(on: app.db)

        guard let jurisdictionId = jurisdiction.id else {
            Issue.record("Jurisdiction ID is nil")
            return
        }

        // Insert an entity type using both name and jurisdiction as lookup
        let record: [String: Any] = [
            "name": "LLC",
            "jurisdiction": ["name": "California"],
        ]

        try await StandardsDALConfiguration.insertEntityType(
            record: record,
            lookupFields: ["name", "jurisdiction_id"],
            database: app.db
        )

        // Try to insert again with same name and jurisdiction (should update)
        try await StandardsDALConfiguration.insertEntityType(
            record: record,
            lookupFields: ["name", "jurisdiction_id"],
            database: app.db
        )

        // Verify only one record exists
        let entityTypes = try await EntityType.query(on: app.db)
            .filter(\.$name == "LLC")
            .filter(\.$jurisdiction.$id == jurisdictionId)
            .all()

        #expect(entityTypes.count == 1)

        try await app.asyncShutdown()
    }

    // MARK: - Foreign Key Resolution Tests

    @Test("Foreign keys resolve via nested YAML references")
    func testForeignKeyResolutionViaNestedReferences() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // Create a jurisdiction
        let jurisdictionRecord: [String: Any] = [
            "name": "Nevada",
            "code": "NV",
            "jurisdiction_type": "state",
        ]

        try await StandardsDALConfiguration.insertJurisdiction(
            record: jurisdictionRecord,
            lookupFields: ["code"],
            database: app.db
        )

        // Create an entity type that references jurisdiction by name
        let entityTypeRecord: [String: Any] = [
            "name": "Corporation",
            "jurisdiction": ["name": "Nevada"],
        ]

        try await StandardsDALConfiguration.insertEntityType(
            record: entityTypeRecord,
            lookupFields: ["name", "jurisdiction_id"],
            database: app.db
        )

        // Verify the entity type has correct jurisdiction reference
        let entityType = try await EntityType.query(on: app.db)
            .filter(\.$name == "Corporation")
            .with(\.$jurisdiction)
            .first()

        #expect(entityType != nil)
        #expect(entityType?.jurisdiction.name == "Nevada")
        #expect(entityType?.jurisdiction.code == "NV")

        try await app.asyncShutdown()
    }

    @Test("Person with nested address relationships")
    func testPersonWithNestedAddressRelationships() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // Create a person
        let personRecord: [String: Any] = [
            "name": "John Doe",
            "email": "john@example.com",
        ]

        try await StandardsDALConfiguration.insertPerson(
            record: personRecord,
            lookupFields: ["email"],
            database: app.db
        )

        // Verify person was created
        let person = try await Person.query(on: app.db)
            .filter(\.$email == "john@example.com")
            .first()

        #expect(person != nil)
        #expect(person?.name == "John Doe")

        // Create an address that references this person
        let addressRecord: [String: Any] = [
            "street": "123 Main St",
            "city": "Test City",
            "state": "CA",
            "zip": "12345",
            "country": "USA",
            "is_verified": true,
            "person": ["email": "john@example.com"],
        ]

        try await StandardsDALConfiguration.insertAddress(
            record: addressRecord,
            lookupFields: ["zip", "person_id"],
            database: app.db
        )

        // Verify address was created with correct person reference
        let address = try await Address.query(on: app.db)
            .filter(\.$street == "123 Main St")
            .with(\.$person)
            .first()

        #expect(address != nil)
        #expect(address?.zip == "12345")
        #expect(address?.person?.email == "john@example.com")

        try await app.asyncShutdown()
    }

    // MARK: - Data Integrity Tests

    @Test("All seed models load without errors")
    func testAllSeedModelsLoadWithoutErrors() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // Run all seeds
        let seedCount = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            environment: app.environment,
            logger: app.logger
        )

        #expect(seedCount > 0)

        // Verify each model has data
        let jurisdictions = try await Jurisdiction.query(on: app.db).all()
        #expect(jurisdictions.count > 0)

        let entityTypes = try await EntityType.query(on: app.db).all()
        #expect(entityTypes.count > 0)

        let questions = try await Question.query(on: app.db).all()
        #expect(questions.count > 0)

        let people = try await Person.query(on: app.db).all()
        #expect(people.count > 0)

        let users = try await User.query(on: app.db).all()
        #expect(users.count > 0)

        try await app.asyncShutdown()
    }

    @Test("Idempotent seed loading (can run seeds multiple times)")
    func testIdempotentSeedLoading() async throws {
        let app = try await Application.make(.testing)

        try await StandardsDALConfiguration.configureForTesting(app)

        // Run seeds first time
        let firstRunCount = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            environment: app.environment,
            logger: app.logger
        )

        #expect(firstRunCount > 0)

        let firstRunJurisdictionCount = try await Jurisdiction.query(on: app.db).count()

        // Run seeds second time
        let secondRunCount = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            environment: app.environment,
            logger: app.logger
        )

        #expect(secondRunCount > 0)

        // Verify counts are the same (no duplicates created)
        let secondRunJurisdictionCount = try await Jurisdiction.query(on: app.db).count()
        #expect(firstRunJurisdictionCount == secondRunJurisdictionCount)

        try await app.asyncShutdown()
    }
}
