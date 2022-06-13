import Fluent

extension Reply {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Reply.schema)
                .id()
                .field("user_id", .uuid, .required)
                .unique(on: "user_id")
                .field("blob", .string, .required)
                .field("expiry", .datetime, .required)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Reply.schema).delete()
        }
    }
}
