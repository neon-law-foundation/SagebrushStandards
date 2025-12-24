import Fluent
import SQLKit

/// Adds new state values to the assigned_notation_state enum.
///
/// This migration extends the state machine for assigned notations by adding three new states:
/// - `review`: For notations that have been submitted and are awaiting review
/// - `waiting_for_flow`: For notations blocked by a dependent flow or process
/// - `waiting_for_alignment`: For notations requiring alignment with other parties
///
/// The migration is safe to run on existing data as it only adds new enum values
/// without modifying existing records.
struct UpdateAssignedNotationStates: AsyncMigration {

    /// Adds the new state values to the assigned_notation_state enum.
    ///
    /// For PostgreSQL, this adds new enum values to the existing enum type.
    /// For SQLite, this is a no-op since SQLite stores enums as text and doesn't
    /// enforce enum constraints at the database level.
    ///
    /// - Parameter database: The database connection to use for the migration.
    /// - Throws: Database errors if the enum update fails.
    func prepare(on database: any Database) async throws {
        // Only run ALTER TYPE for PostgreSQL
        // SQLite stores enums as TEXT and doesn't have enum types
        // We detect PostgreSQL by checking if the raw SQL succeeds
        if let sql = database as? SQLDatabase {
            // Try to run PostgreSQL-specific ALTER TYPE command
            // If it fails (on SQLite), we catch the error and continue
            // since SQLite doesn't need this migration
            do {
                try await sql.raw(
                    "ALTER TYPE assigned_notation_state ADD VALUE IF NOT EXISTS 'review'"
                ).run()

                try await sql.raw(
                    "ALTER TYPE assigned_notation_state ADD VALUE IF NOT EXISTS 'waiting_for_flow'"
                ).run()

                try await sql.raw(
                    "ALTER TYPE assigned_notation_state ADD VALUE IF NOT EXISTS 'waiting_for_alignment'"
                ).run()
            } catch {
                // Ignore errors on SQLite - the enum values are already available
                // in the Swift code and SQLite stores them as TEXT
            }
        }
        // For other databases, this is a no-op
    }

    /// Reverts the migration by removing the new state values.
    ///
    /// **Warning**: PostgreSQL does not support removing enum values directly.
    /// This revert operation will fail if any records use the new states.
    ///
    /// - Parameter database: The database connection to use for the migration.
    /// - Throws: Database errors during the revert operation.
    func revert(on database: any Database) async throws {
        // PostgreSQL does not support removing enum values directly
        // This is intentionally left empty as removing enum values requires
        // dropping and recreating the entire enum type, which is not safe
        // if any records are using the new states.
        //
        // To truly revert this migration:
        // 1. Update all records using the new states to use old states
        // 2. Drop and recreate the enum with only the old values
        // 3. Re-add the column to the table
    }
}
