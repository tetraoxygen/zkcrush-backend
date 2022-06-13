import Fluent
import Vapor

struct ReplyController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let replies = routes.grouped("replies")
        replies.post(use: create)
        replies.delete(use: delete)
        replies.group(":userID") { reply in
            reply.get(use: lookup)
        }

    }

    struct ReplyRequest: Content {
        /// The user's ID. NOTE: Make this actually gated behind tokens at some point, but for testing this is fine.
        var userID: UserAuthenticationPlaceholder
        /// The encrypted (using the public from the confession of the crush) blob of the key for the reply.
        var blob: String
    }

    struct UserAuthenticationPlaceholder: Content {
        var userID: UUID
    }

    func lookup(req: Request) async throws -> Reply {
        guard let idString = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "No user ID provided.")
        }

        guard let userID = UUID(uuidString: idString) else {
            throw Abort(.badRequest, reason: "Invalid user ID.")
        }

        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        guard let reply = try await user.$reply.get(on: req.db) else {
            throw Abort(.notFound, reason: "No reply for this user.")
        }

        return reply
    }

    /// Create a new reply.
    func create(req: Request) async throws -> Reply {
        let replyRequest = try req.content.decode(ReplyRequest.self)

        guard let user = try await User.find(replyRequest.userID.userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        if let existingReply = try await user.$reply.get(on: req.db) {
            if existingReply.expiry > Date() {
                throw Abort(.badRequest, reason: "You can only have one confession or reply at a time before expiry.")
            } else { // Reply has expired, so we can clear room for a new one.
                try await existingReply.delete(on: req.db)
            }
        }

        let reply = Reply(blob: replyRequest.blob)

        try await user.$reply.create(reply, on: req.db)

        return reply
    }

    func delete(req: Request) async throws -> HTTPStatus {
        let authenticationPlaceholder = try req.content.decode(UserAuthenticationPlaceholder.self)

        guard let user = try await User.find(authenticationPlaceholder.userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        if let existingReply = try await user.$reply.get(on: req.db) {
            try await existingReply.delete(on: req.db)
        }

        return .ok
    }
}
