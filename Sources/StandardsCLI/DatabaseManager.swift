import Fluent
import FluentSQLiteDriver
import Foundation
import Logging
import StandardsDAL
import Vapor

/// Manages in-memory SQLite database for the CLI
public actor DatabaseManager {
    private let app: Application
    private let logger: Logger

    public init() async throws {
        self.logger = Logger(label: "standards-cli")

        var env = Environment(name: "testing", arguments: ["vapor"])
        try LoggingSystem.bootstrap(from: &env)

        self.app = try await Application.make(env)

        setenv("ENV", "testing", 1)

        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.logger = logger

        try await StandardsDALConfiguration.configure(app)

        logger.info("Database configured: SQLite (in-memory)")
    }

    nonisolated public func getDatabase() -> Database {
        app.db
    }

    public func shutdown() async throws {
        try await app.asyncShutdown()
    }
}
