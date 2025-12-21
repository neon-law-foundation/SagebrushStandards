import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Foundation
import Logging
import Vapor
import Yams

/// Configuration utility for setting up the database with all migrations
public struct StandardsDALConfiguration {

    /// Configure the database and run all migrations
    /// Uses ENV environment variable to determine database:
    /// - ENV=production: PostgreSQL
    /// - Otherwise: SQLite (in-memory for testing, file-based for development)
    public static func configure(_ app: Application) async throws {
        let env = Environment.get("ENV")?.lowercased() ?? "development"
        let isProduction = env == "production"

        // Configure database driver based on environment
        if isProduction {
            // Production: Use PostgreSQL
            let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
            let port = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5432
            let username = Environment.get("DATABASE_USERNAME") ?? "postgres"
            let password = Environment.get("DATABASE_PASSWORD") ?? ""
            let database = Environment.get("DATABASE_NAME") ?? "standards"

            // Use new SQLPostgresConfiguration API
            let config = SQLPostgresConfiguration(
                hostname: hostname,
                port: port,
                username: username,
                password: password,
                database: database,
                tls: .disable
            )

            app.databases.use(
                DatabaseConfigurationFactory.postgres(configuration: config),
                as: .psql
            )

            app.logger.info("Database configured: PostgreSQL at \(hostname):\(port)/\(database)")
        } else {
            // Development/Testing: Use SQLite
            // Use in-memory for testing environment, file-based for development
            let isTestEnvironment = env == "testing" || app.environment == .testing

            if isTestEnvironment {
                app.databases.use(DatabaseConfigurationFactory.sqlite(.memory), as: .sqlite)
                app.logger.info("Database configured: SQLite (in-memory)")
            } else {
                let dbPath = Environment.get("DATABASE_PATH") ?? "db/standards.sqlite"
                app.databases.use(DatabaseConfigurationFactory.sqlite(.file(dbPath)), as: .sqlite)
                app.logger.info("Database configured: SQLite at \(dbPath)")
            }
        }

        // Add all migrations in order
        app.migrations.add(CreatePeople())
        app.migrations.add(CreateUsers())
        app.migrations.add(CreateJurisdictions())
        app.migrations.add(CreateEntityTypes())
        app.migrations.add(CreateEntities())
        app.migrations.add(CreateShareClasses())
        app.migrations.add(CreateBlobs())
        app.migrations.add(CreateProjects())
        app.migrations.add(CreateCredentials())
        app.migrations.add(CreateRelationshipLogs())
        app.migrations.add(CreateDisclosures())
        app.migrations.add(CreateQuestions())
        app.migrations.add(CreateAddresses())
        app.migrations.add(CreateMailboxes())
        app.migrations.add(CreatePersonEntityRoles())

        // Run migrations
        try await app.autoMigrate()
        app.logger.info("Database migrations completed")
    }

    /// Run seeds from YAML files and return the count of records seeded
    public static func runSeeds(on database: Database, environment: Environment, logger: Logger) async throws -> Int {
        var totalSeeds = 0
        let seedOrder: [String] = [
            "Jurisdiction",
            "EntityType",
            "Question",
            "Person",
            "User",
            "Entity",
            "Credential",
            "Address",
            "Mailbox",
            "PersonEntityRole",
        ]

        logger.info("Starting seed process")

        for modelName in seedOrder {
            logger.info("Processing seeds for model: \(modelName)")

            if let seedFile = findSeedFile(for: modelName, environment: environment, logger: logger) {
                logger.info("Loading seed file: \(seedFile)")
                let count = try await processSeedFile(
                    seedFile,
                    modelName: modelName,
                    database: database,
                    logger: logger
                )
                totalSeeds += count
            }
        }

        logger.info("Seed process completed: \(totalSeeds) total records")
        return totalSeeds
    }

    /// Find seed file for a model
    private static func findSeedFile(for modelName: String, environment: Environment, logger: Logger) -> String? {
        // Try Bundle.module first
        if let seedURL = Bundle.module.url(forResource: "Seeds/\(modelName)", withExtension: "yaml") {
            if FileManager.default.fileExists(atPath: seedURL.path) {
                logger.info("Found seed file via Bundle.module: \(seedURL.path)")
                return modelName
            }
        }

        // Fallback: try relative path
        let fallbackPath = "Sources/StandardsDAL/Seeds/\(modelName).yaml"
        if FileManager.default.fileExists(atPath: fallbackPath) {
            logger.info("Found seed file via fallback path: \(fallbackPath)")
            return modelName
        }

        logger.warning("No seed file found for model: \(modelName)")
        return nil
    }

    /// Process a seed file and return count of records seeded
    private static func processSeedFile(
        _ seedFile: String,
        modelName: String,
        database: Database,
        logger: Logger
    ) async throws -> Int {
        var seedURL: URL?

        // Try Bundle.module first
        if let bundleURL = Bundle.module.url(forResource: "Seeds/\(seedFile)", withExtension: "yaml") {
            if FileManager.default.fileExists(atPath: bundleURL.path) {
                seedURL = bundleURL
            }
        }

        // Fallback: try relative path
        if seedURL == nil {
            let fallbackPath = "Sources/StandardsDAL/Seeds/\(seedFile).yaml"
            if FileManager.default.fileExists(atPath: fallbackPath) {
                seedURL = URL(fileURLWithPath: fallbackPath)
            }
        }

        guard let finalURL = seedURL else {
            logger.warning("Seed file not found: Seeds/\(seedFile).yaml")
            return 0
        }

        logger.info("Processing seed file: \(finalURL.path)")

        // Read and parse YAML file
        let yamlData = try Data(contentsOf: finalURL)
        let seedData = try parseYAML(from: yamlData)

        logger.info("Found \(seedData.records.count) \(modelName) records with lookup fields: \(seedData.lookupFields)")

        // Process each record
        for (index, record) in seedData.records.enumerated() {
            do {
                try await insertRecord(
                    record: record,
                    modelName: modelName,
                    lookupFields: seedData.lookupFields,
                    database: database,
                    logger: logger
                )
                logger.debug("✓ Inserted \(modelName) record \(index + 1)/\(seedData.records.count)")
            } catch {
                logger.error("✗ Failed to insert \(modelName) record \(index + 1): \(error)")
            }
        }

        logger.info("Completed processing \(seedData.records.count) \(modelName) records")
        return seedData.records.count
    }

    /// Parse YAML data into seed structure
    private static func parseYAML(from data: Data) throws -> SeedData {
        let yaml = try Yams.load(yaml: String(data: data, encoding: .utf8)!)

        guard let yamlDict = yaml as? [String: Any] else {
            throw SeedError.invalidYAMLStructure
        }

        let lookupFields = yamlDict["lookup_fields"] as? [String] ?? []
        let records = yamlDict["records"] as? [[String: Any]] ?? []

        return SeedData(lookupFields: lookupFields, records: records)
    }

    /// Insert or update a record using native Fluent
    private static func insertRecord(
        record: [String: Any],
        modelName: String,
        lookupFields: [String],
        database: Database,
        logger: Logger
    ) async throws {
        switch modelName {
        case "Jurisdiction":
            try await insertJurisdiction(record: record, lookupFields: lookupFields, database: database)
        case "EntityType":
            try await insertEntityType(record: record, lookupFields: lookupFields, database: database)
        case "Question":
            try await insertQuestion(record: record, lookupFields: lookupFields, database: database)
        case "Person":
            try await insertPerson(record: record, lookupFields: lookupFields, database: database)
        case "User":
            try await insertUser(record: record, lookupFields: lookupFields, database: database)
        case "Entity":
            try await insertEntity(record: record, lookupFields: lookupFields, database: database)
        case "Credential":
            try await insertCredential(record: record, lookupFields: lookupFields, database: database)
        case "Address":
            try await insertAddress(record: record, lookupFields: lookupFields, database: database)
        case "Mailbox":
            try await insertMailbox(record: record, lookupFields: lookupFields, database: database)
        case "PersonEntityRole":
            try await insertPersonEntityRole(record: record, lookupFields: lookupFields, database: database)
        default:
            logger.warning("Unknown model type: \(modelName)")
        }
    }

    /// Configure database for testing with SQLite (in-memory)
    /// Sets ENV=testing to force in-memory SQLite
    public static func configureForTesting(_ app: Application) async throws {
        // Ensure testing environment
        setenv("ENV", "testing", 1)
        try await configure(app)
    }

    /// Configure database for production with PostgreSQL
    /// Sets ENV=production to force PostgreSQL
    public static func configureForProduction(_ app: Application) async throws {
        // Ensure production environment
        setenv("ENV", "production", 1)
        try await configure(app)
    }
}

// MARK: - Supporting Types

struct SeedData {
    let lookupFields: [String]
    let records: [[String: Any]]
}

enum SeedError: Error {
    case invalidYAMLStructure
    case missingRequiredField(String)
    case unsupportedModel(String)
}
