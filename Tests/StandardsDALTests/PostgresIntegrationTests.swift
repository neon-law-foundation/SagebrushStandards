import Fluent
import FluentPostgresDriver
import StandardsDAL
import Testing
import Vapor

/// Integration tests that run against a real PostgreSQL database
/// These tests require Docker and docker-compose to be running
///
/// To run these tests:
/// 1. Start PostgreSQL: docker-compose up -d
/// 2. Run tests: ENV=production DATABASE_HOST=localhost DATABASE_PORT=5432 DATABASE_USERNAME=postgres DATABASE_PASSWORD=postgres DATABASE_NAME=standards_test swift test --filter PostgresIntegrationTests
/// 3. Stop PostgreSQL: docker-compose down
///
/// NOTE: These tests are currently disabled by default due to environment setup complexity.
/// Use the script ./scripts/test-local-postgres.sh for local PostgreSQL testing.
/// The SQLite-based MigrationIntegrationTests provide comprehensive coverage.
@Suite("PostgreSQL Integration Tests")
struct PostgresIntegrationTests {

    @Test("MigrationRunner works against real PostgreSQL", .disabled("Requires manual PostgreSQL setup"))
    func testMigrationRunnerAgainstPostgres() async throws {
        // This test requires PostgreSQL to be running via docker-compose
        let app = try await Application.make(.testing)

        // Configure PostgreSQL (environment variables should already be set)
        try await StandardsDALConfiguration.configureForProduction(app)

        // Verify migrations ran
        let jurisdictionCount = try await Jurisdiction.query(on: app.db).count()
        #expect(jurisdictionCount >= 0)

        // Run seeds
        let seedCount = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            environment: app.environment,
            logger: app.logger
        )

        #expect(seedCount > 0)

        // Verify data was inserted
        let jurisdictions = try await Jurisdiction.query(on: app.db).all()
        #expect(jurisdictions.count > 0)

        try await app.asyncShutdown()
    }

    @Test("Seeds load correctly in PostgreSQL", .disabled("Requires manual PostgreSQL setup"))
    func testSeedsLoadInPostgres() async throws {
        let app = try await Application.make(.testing)

        // Configure PostgreSQL (environment variables should already be set)
        try await StandardsDALConfiguration.configureForProduction(app)

        // Run seeds
        let seedCount = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            environment: app.environment,
            logger: app.logger
        )

        #expect(seedCount > 0)

        // Verify specific data
        let nevada = try await Jurisdiction.query(on: app.db)
            .filter(\.$code == "NV")
            .first()

        #expect(nevada != nil)
        #expect(nevada?.name == "Nevada")

        // Verify entity types with jurisdiction relationships
        let entityTypes = try await EntityType.query(on: app.db)
            .with(\.$jurisdiction)
            .all()

        #expect(entityTypes.count > 0)

        for entityType in entityTypes {
            #expect(entityType.jurisdiction.name != "")
        }

        try await app.asyncShutdown()
    }

    // MARK: - Helper

    /// Check if PostgreSQL is available
    /// Returns true if DATABASE_HOST environment variable is set
    private static func isPostgresAvailable() -> Bool {
        Environment.get("DATABASE_HOST") != nil
    }
}
