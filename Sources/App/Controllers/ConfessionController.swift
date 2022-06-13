import Fluent
import Vapor

struct ConfessionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let confessions = routes.grouped("confessions")
        confessions.post(use: create)
        confessions.delete(use: delete)
        confessions.group(":userID") { confession in
            confession.get(use: lookup)
        }

    }

    struct ConfessionRequest: Content {
        /// The user's ID. NOTE: Make this actually gated behind tokens at some point, but for testing this is fine.
        var userID: UserAuthenticationPlaceholder
        /// The encrypted (using the public key of the crush) blob of the key for the confession.
        var blob: String
    }

    struct UserAuthenticationPlaceholder: Content {
        var userID: UUID
    }

    func lookup(req: Request) async throws -> Confession {
        guard let idString = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "No user ID provided.")
        }

        guard let userID = UUID(uuidString: idString) else {
            throw Abort(.badRequest, reason: "Invalid user ID.")
        }

        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        guard let confession = try await user.$confession.get(on: req.db) else {
            throw Abort(.notFound, reason: "No confession for this user.")
        }

        return confession
    }

    /// Create a new confession.
    func create(req: Request) async throws -> Confession {
        let confessionRequest = try req.content.decode(ConfessionRequest.self)

        guard let user = try await User.find(confessionRequest.userID.userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        if let existingConfession = try await user.$confession.get(on: req.db) {
            if existingConfession.expiry > Date() {
                throw Abort(.badRequest, reason: "You can only have one confession or reply at a time before expiry.")
            } else { // Confession has expired, so we can clear room for a new one.
                try await existingConfession.delete(on: req.db)
            }
        }

        let confession = Confession(blob: confessionRequest.blob)

        try await user.$confession.create(confession, on: req.db)

        return confession
    }

    func delete(req: Request) async throws -> HTTPStatus {
        let authenticationPlaceholder = try req.content.decode(UserAuthenticationPlaceholder.self)

        guard let user = try await User.find(authenticationPlaceholder.userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        if let existingConfession = try await user.$confession.get(on: req.db) {
            try await existingConfession.delete(on: req.db)
        }

        return .ok
    }
}
