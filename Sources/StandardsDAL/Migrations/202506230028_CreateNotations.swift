import Fluent

struct CreateNotations: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Create enum for respondent types
        let respondentType = try await database.enum("respondent_type")
            .case("person")
            .case("entity")
            .case("person_and_entity")
            .create()

        try await database.schema(Notation.schema)
            .field("id", .int32, .identifier(auto: true))
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("respondent_type", respondentType, .required)
            .field("markdown_content", .string, .required)
            .field("frontmatter", .json, .required)
            .field("owner_id", .int32, .references(Entity.schema, "id"))
            .field("inserted_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Notation.schema).delete()
        try await database.enum("respondent_type").delete()
    }
}
