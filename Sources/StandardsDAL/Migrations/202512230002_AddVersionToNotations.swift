import Fluent

/// Adds a version field to the notations table to track git commit SHAs.
///
/// The version field stores the git commit SHA from the main branch of the repository
/// where each notation originated. This enables audit trails and version control integration,
/// allowing the system to track exactly which version of a notation template is being used.
struct AddVersionToNotations: AsyncMigration {

    /// Adds the version column to the notations table.
    ///
    /// The column is added as required (NOT NULL) with a default empty string value
    /// for existing records. New records should populate this field with the actual
    /// git commit SHA.
    ///
    /// - Parameter database: The database connection to use for the migration.
    /// - Throws: Database errors if the column addition fails.
    func prepare(on database: any Database) async throws {
        try await database.schema(Notation.schema)
            .field("version", .string, .required, .sql(.default("")))
            .update()
    }

    /// Reverts the migration by removing the version column.
    ///
    /// - Parameter database: The database connection to use for the migration.
    /// - Throws: Database errors during the revert operation.
    func revert(on database: any Database) async throws {
        try await database.schema(Notation.schema)
            .deleteField("version")
            .update()
    }
}
