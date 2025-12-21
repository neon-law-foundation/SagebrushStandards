import Fluent
import FluentPostgresDriver
import Foundation
import Logging
import StandardsDAL
import Testing
import Vapor

/// Integration tests for MigrationRunner against PostgreSQL
/// These tests require a running PostgreSQL instance (use Docker)
@Suite("MigrationRunner Integration Tests", .serialized)
struct MigrationRunnerIntegrationTests {

    /// Test helper for creating a PostgreSQL-backed Vapor application
    static func withPostgreSQLApp<T>(
        _ test: (Application, Database) async throws -> T
    ) async throws -> T {
        let app = try await Application.make(.testing)

        do {
            // Force PostgreSQL configuration
            setenv("ENV", "production", 1)
            setenv("DATABASE_HOST", "localhost", 1)
            setenv("DATABASE_PORT", "5433", 1)
            setenv("DATABASE_USERNAME", "postgres", 1)
            setenv("DATABASE_PASSWORD", "postgres", 1)
            setenv("DATABASE_NAME", "standards_test", 1)

            try await StandardsDALConfiguration.configure(app)

            let result = try await test(app, app.db)

            // Clean up: revert migrations
            try await app.autoRevert()
            try await app.asyncShutdown()

            return result
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
    }

    @Test("Migrations run successfully against PostgreSQL")
    func testMigrationsRunSuccessfully() async throws {
        try await Self.withPostgreSQLApp { app, database in
            // Verify migrations ran by checking that we can query models
            let people = try await Person.query(on: database).all()
            // Just verify the table exists (no error thrown)
            #expect(people.count >= 0, "Expected 'people' table to exist after migrations")

            // Verify other key tables by querying them
            let jurisdictions = try await Jurisdiction.query(on: database).all()
            #expect(jurisdictions.count >= 0, "Expected 'jurisdictions' table to exist")

            let entityTypes = try await EntityType.query(on: database).all()
            #expect(entityTypes.count >= 0, "Expected 'entity_types' table to exist")

            let entities = try await Entity.query(on: database).all()
            #expect(entities.count >= 0, "Expected 'entities' table to exist")

            let users = try await User.query(on: database).all()
            #expect(users.count >= 0, "Expected 'users' table to exist")
        }
    }

    @Test("Seeds load successfully from YAML files")
    func testSeedsLoadSuccessfully() async throws {
        try await Self.withPostgreSQLApp { app, database in
            let logger = Logger(label: "test")

            // Run seeds
            let seedCount = try await StandardsDALConfiguration.runSeeds(
                on: database,
                environment: app.environment,
                logger: logger
            )

            #expect(seedCount > 0, "Expected at least one seed to be loaded")

            // Verify jurisdictions were loaded
            let jurisdictions = try await Jurisdiction.query(on: database).all()
            #expect(!jurisdictions.isEmpty, "Expected jurisdictions to be seeded")

            // Verify entity types were loaded
            let entityTypes = try await EntityType.query(on: database).all()
            #expect(!entityTypes.isEmpty, "Expected entity types to be seeded")

            // Verify questions were loaded
            let questions = try await Question.query(on: database).all()
            #expect(!questions.isEmpty, "Expected questions to be seeded")
        }
    }

    @Test("Upsert behavior works with lookup_fields")
    func testUpsertBehaviorWithLookupFields() async throws {
        try await Self.withPostgreSQLApp { app, database in
            let logger = Logger(label: "test")

            // Run seeds first time
            _ = try await StandardsDALConfiguration.runSeeds(
                on: database,
                environment: app.environment,
                logger: logger
            )

            let firstJurisdictionCount = try await Jurisdiction.query(on: database).count()

            // Run seeds second time - should upsert, not duplicate
            _ = try await StandardsDALConfiguration.runSeeds(
                on: database,
                environment: app.environment,
                logger: logger
            )

            let secondJurisdictionCount = try await Jurisdiction.query(on: database).count()

            // Counts should match - no duplicates
            #expect(
                firstJurisdictionCount == secondJurisdictionCount,
                "Expected upsert to prevent duplicates"
            )

            // Verify specific jurisdiction can be found and updated
            if let california = try await Jurisdiction.query(on: database)
                .filter(\.$code == "CA")
                .first()
            {
                #expect(california.name == "California", "Expected California jurisdiction to exist")
            } else {
                Issue.record("California jurisdiction not found in seeds")
            }
        }
    }

    @Test("Foreign key resolution works for nested YAML references")
    func testForeignKeyResolution() async throws {
        try await Self.withPostgreSQLApp { app, database in
            let logger = Logger(label: "test")

            // Run seeds
            _ = try await StandardsDALConfiguration.runSeeds(
                on: database,
                environment: app.environment,
                logger: logger
            )

            // Verify EntityTypes have proper jurisdiction foreign keys
            let entityTypes = try await EntityType.query(on: database)
                .with(\.$jurisdiction)
                .all()

            #expect(!entityTypes.isEmpty, "Expected entity types to be loaded")

            for entityType in entityTypes {
                // Verify jurisdiction relationship is properly set (ID > 0)
                #expect(
                    entityType.$jurisdiction.id > 0,
                    "Expected entity type '\(entityType.name)' to have a jurisdiction"
                )
            }

            // Verify Entities have proper entity type foreign keys
            let entities = try await Entity.query(on: database)
                .with(\.$legalEntityType)
                .all()

            if !entities.isEmpty {
                for entity in entities {
                    #expect(
                        entity.$legalEntityType.id > 0,
                        "Expected entity '\(entity.name)' to have an entity type"
                    )
                }
            }

            // Verify Users have proper person foreign keys
            let users = try await User.query(on: database)
                .with(\.$person)
                .all()

            if !users.isEmpty {
                for user in users {
                    #expect(
                        user.$person.id > 0,
                        "Expected user to have a person"
                    )
                }
            }
        }
    }

    @Test("Specific seed data is loaded correctly")
    func testSpecificSeedDataLoaded() async throws {
        try await Self.withPostgreSQLApp { app, database in
            let logger = Logger(label: "test")

            // Run seeds
            _ = try await StandardsDALConfiguration.runSeeds(
                on: database,
                environment: app.environment,
                logger: logger
            )

            // Verify specific jurisdictions from Jurisdiction.yaml
            let california = try await Jurisdiction.query(on: database)
                .filter(\.$code == "CA")
                .first()

            #expect(california != nil, "Expected California jurisdiction")
            #expect(california?.name == "California")
            #expect(california?.jurisdictionType == .state)

            // Verify Nevada
            let nevada = try await Jurisdiction.query(on: database)
                .filter(\.$code == "NV")
                .first()

            #expect(nevada != nil, "Expected Nevada jurisdiction")
            #expect(nevada?.name == "Nevada")

            // Verify at least one EntityType exists with proper foreign key
            let llcType = try await EntityType.query(on: database)
                .filter(\.$name == "Limited Liability Company")
                .with(\.$jurisdiction)
                .first()

            if let llcType = llcType {
                #expect(llcType.$jurisdiction.id > 0, "Expected LLC to have jurisdiction")
            }
        }
    }

    @Test("Address seed with entity foreign key resolution")
    func testAddressForeignKeyResolution() async throws {
        try await Self.withPostgreSQLApp { app, database in
            let logger = Logger(label: "test")

            // Run seeds
            _ = try await StandardsDALConfiguration.runSeeds(
                on: database,
                environment: app.environment,
                logger: logger
            )

            // Verify addresses with entity relationships
            let addresses = try await Address.query(on: database)
                .with(\.$entity)
                .all()

            if !addresses.isEmpty {
                for address in addresses where address.$entity.id != nil {
                    // If address has an entity, verify it exists
                    let entity = try await Entity.find(address.$entity.id, on: database)
                    #expect(entity != nil, "Expected entity to exist for address")
                }
            }
        }
    }
}
