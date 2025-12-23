import Fluent
import FluentSQLiteDriver
import Foundation
import StandardsDAL
import Vapor

/// Test utilities for StandardsDAL testing
enum TestUtilities {

    /// Test helper for creating configured Vapor applications
    static func withApp<T>(_ test: (Application, Database) async throws -> T) async throws -> T {
        let app = try await Application.make(.testing)
        do {
            try await StandardsDALConfiguration.configureForTesting(app)
            let result = try await test(app, app.db)
            try await app.autoRevert()
            try await app.asyncShutdown()
            return result
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
    }

    /// Generate a random string with timestamp for unique identifiers
    static func randomUID(prefix: String = "test") -> String {
        let timestamp = Date().timeIntervalSince1970
        let randomSuffix = UUID().uuidString.prefix(8)
        return "\(prefix)_\(Int(timestamp))_\(randomSuffix)"
    }

    /// Generate a random code for testing
    static func randomCode(prefix: String = "CODE") -> String {
        let randomSuffix = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)
        return "\(prefix)\(randomSuffix)".uppercased()
    }

    /// Generate a random string for general use
    static func randomString(length: Int = 8) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    /// Create a test person with unique email
    static func createTestPerson(name: String? = nil, email: String? = nil) -> Person {
        let person = Person()
        person.name = name ?? randomUID(prefix: "TestPerson")
        person.email = email ?? randomUID(prefix: "test") + "@example.com"
        return person
    }

    /// Create a test jurisdiction with unique code and name
    static func createTestJurisdiction(
        name: String? = nil,
        code: String? = nil,
        type: JurisdictionType = .state
    ) -> Jurisdiction {
        let jurisdiction = Jurisdiction()
        jurisdiction.name = name ?? randomUID(prefix: "TestJurisdiction")
        jurisdiction.code = code ?? randomCode(prefix: "TJ")
        jurisdiction.jurisdictionType = type
        return jurisdiction
    }

    /// Create a test project with unique codename
    static func createTestProject(codename: String? = nil) -> Project {
        let project = Project()
        project.codename = codename ?? randomUID(prefix: "TestProject")
        return project
    }

    /// Create a test credential
    static func createTestCredential(
        personID: Int32,
        jurisdictionID: Int32,
        licenseNumber: String? = nil
    )
        -> Credential
    {
        let credential = Credential()
        credential.$person.id = personID
        credential.$jurisdiction.id = jurisdictionID
        credential.licenseNumber = licenseNumber ?? randomCode(prefix: "LIC")
        return credential
    }

    /// Create a test entity type
    static func createTestEntityType(jurisdictionID: Int32, name: String? = nil) -> EntityType {
        let entityType = EntityType()
        entityType.$jurisdiction.id = jurisdictionID
        entityType.name = name ?? randomUID(prefix: "TestEntityType")
        return entityType
    }

    /// Create a test entity
    static func createTestEntity(name: String? = nil, legalEntityTypeID: Int32) -> Entity {
        let entity = Entity()
        entity.name = name ?? randomUID(prefix: "TestEntity")
        entity.$legalEntityType.id = legalEntityTypeID
        return entity
    }

    /// Create a test address for a person
    static func createTestAddressForPerson(
        personID: Int32,
        street: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil,
        country: String? = nil
    ) -> Address {
        let address = Address()
        address.$person.id = personID
        address.$entity.id = nil
        address.street = street ?? "\(randomString(length: 3)) \(randomUID(prefix: "Test")) St"
        address.city = city ?? randomUID(prefix: "TestCity")
        address.state = state ?? "CA"
        address.zip = zip ?? "90210"
        address.country = country ?? "USA"
        address.isVerified = false
        return address
    }

    /// Create a test address for an entity
    static func createTestAddressForEntity(
        entityID: Int32,
        street: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil,
        country: String? = nil
    ) -> Address {
        let address = Address()
        address.$person.id = nil
        address.$entity.id = entityID
        address.street = street ?? "\(randomString(length: 3)) \(randomUID(prefix: "Test")) St"
        address.city = city ?? randomUID(prefix: "TestCity")
        address.state = state ?? "CA"
        address.zip = zip ?? "90210"
        address.country = country ?? "USA"
        address.isVerified = false
        return address
    }

    /// Create a complete owner entity with jurisdiction and entity type
    static func createTestOwnerEntity(on database: Database) async throws -> Int32 {
        let jurisdiction = createTestJurisdiction()
        try await jurisdiction.save(on: database)
        let jurisdictionID = try jurisdiction.requireID()

        let entityType = createTestEntityType(jurisdictionID: jurisdictionID)
        try await entityType.save(on: database)
        let entityTypeID = try entityType.requireID()

        let owner = createTestEntity(legalEntityTypeID: entityTypeID)
        try await owner.save(on: database)
        return try owner.requireID()
    }
}
