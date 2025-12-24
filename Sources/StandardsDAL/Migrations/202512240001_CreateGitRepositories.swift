import Fluent
import SQLKit

/// Creates the git_repositories table for tracking AWS CodeCommit repositories.
///
/// This migration creates a table to store metadata about AWS CodeCommit repositories
/// that contain notation templates. Each repository is uniquely identified by its
/// CodeCommit repository ID, and includes AWS account and region information for
/// constructing ARNs and API calls.
struct CreateGitRepositories: AsyncMigration {

    /// Creates the git_repositories table with all required fields and constraints.
    ///
    /// - Parameter database: The database connection to use for the migration.
    /// - Throws: Database errors if table creation fails.
    func prepare(on database: any Database) async throws {
        try await database.schema(GitRepository.schema)
            .field("id", .int32, .identifier(auto: true))
            .field("aws_account_id", .string, .required)
            .field("aws_region", .string, .required)
            .field("codecommit_repository_id", .string, .required)
            .field("repository_name", .string, .required)
            .field("repository_arn", .string, .required)
            .field("description", .string)
            .field("inserted_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "codecommit_repository_id")
            .create()

        if let sql = database as? SQLDatabase {
            try await sql.raw(
                """
                CREATE INDEX git_repositories_name_idx ON git_repositories (repository_name)
                """
            ).run()

            try await sql.raw(
                """
                CREATE INDEX git_repositories_aws_lookup_idx ON git_repositories (aws_account_id, aws_region)
                """
            ).run()
        }
    }

    /// Reverts the migration by dropping the git_repositories table.
    ///
    /// - Parameter database: The database connection to use for the migration.
    /// - Throws: Database errors during the revert operation.
    func revert(on database: any Database) async throws {
        try await database.schema(GitRepository.schema).delete()
    }
}
