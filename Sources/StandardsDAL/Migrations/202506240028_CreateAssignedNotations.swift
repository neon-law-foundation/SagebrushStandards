import Fluent
import SQLKit

struct CreateAssignedNotations: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Create enum for assigned notation states
        let assignedNotationState = try await database.enum("assigned_notation_state")
            .case("open")
            .case("closed")
            .create()

        try await database.schema(AssignedNotation.schema)
            .field("id", .int32, .identifier(auto: true))
            .field("notation_id", .int32, .required, .references(Notation.schema, "id"))
            .field("person_id", .int32, .references(Person.schema, "id"))
            .field("entity_id", .int32, .references(Entity.schema, "id"))
            .field("state", assignedNotationState, .required)
            .field("inserted_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()

        // Add partial unique index to prevent duplicate open assignments
        // This ensures you can't assign the same notation to the same person/entity combination
        // when state is 'open', but allows multiple closed assignments
        if database is SQLDatabase {
            try await (database as! SQLDatabase).raw(
                """
                CREATE UNIQUE INDEX assigned_notations_unique_open_assignment
                ON assigned_notations (notation_id, COALESCE(person_id, 0), COALESCE(entity_id, 0))
                WHERE state = 'open'
                """
            ).run()
        }
    }

    func revert(on database: any Database) async throws {
        if database is SQLDatabase {
            try await (database as! SQLDatabase).raw(
                "DROP INDEX IF EXISTS assigned_notations_unique_open_assignment"
            ).run()
        }

        try await database.schema(AssignedNotation.schema).delete()
        try await database.enum("assigned_notation_state").delete()
    }
}
