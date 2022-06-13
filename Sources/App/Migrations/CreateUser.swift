import Fluent

extension User {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(User.schema)
                .id()
                .field("name", .string, .required)
                .field("global_key", .string, .required)
                .field("last_confession", .datetime, .required)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(User.schema).delete()
        }
    }
}
