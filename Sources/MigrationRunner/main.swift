import AWSLambdaRuntime
import Foundation
import Logging
import StandardsDAL
import Vapor

struct MigrationRequest: Codable {
    let action: String  // "migrate" or "seed" or "both"
}

struct MigrationResponse: Codable {
    let success: Bool
    let message: String
    let migrationsRun: Int
    let seedsLoaded: Int
}

@main
struct MigrationRunner: SimpleLambdaHandler {
    func handle(_ event: MigrationRequest, context: LambdaContext) async throws -> MigrationResponse {
        let logger = context.logger
        logger.info("Migration Lambda invoked with action: \(event.action)")

        // Create a temporary Vapor Application
        var env = try Environment.detect()
        env.arguments = ["serve"]

        let app = try await Application.make(env)

        // Configure database using StandardsDAL
        try await StandardsDALConfiguration.configure(app)

        var migrationsRun = 0
        var seedsLoaded = 0

        switch event.action.lowercased() {
        case "migrate":
            logger.info("Running migrations only")
            // Migrations already run by configure()
            migrationsRun = 15  // Total number of migrations

        case "seed":
            logger.info("Running seeds only")
            seedsLoaded = try await StandardsDALConfiguration.runSeeds(
                on: app.db,
                environment: app.environment,
                logger: logger
            )

        case "both", "all":
            logger.info("Running migrations and seeds")
            // Migrations already run by configure()
            migrationsRun = 15
            seedsLoaded = try await StandardsDALConfiguration.runSeeds(
                on: app.db,
                environment: app.environment,
                logger: logger
            )

        default:
            try await app.asyncShutdown()
            return MigrationResponse(
                success: false,
                message: "Invalid action: \(event.action). Use 'migrate', 'seed', or 'both'",
                migrationsRun: 0,
                seedsLoaded: 0
            )
        }

        try await app.asyncShutdown()

        logger.info("Migration Lambda completed successfully")
        return MigrationResponse(
            success: true,
            message: "Migration completed successfully",
            migrationsRun: migrationsRun,
            seedsLoaded: seedsLoaded
        )
    }
}
