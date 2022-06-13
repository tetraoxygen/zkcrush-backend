import Fluent
import Vapor

extension User {
    convenience init(_ setupUser: UserController.SetupUser) {
        self.init(name: setupUser.name, globalKey: setupUser.globalKey)
    }
}

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let confessions = routes.grouped("confessions")
        confessions.post(use: create)
        confessions.delete(use: delete)
        confessions.group(":userID") { confession in
            confession.get(use: lookup)
        }

    }

    struct SetupUser: Content {
        var name: String
        var globalKey: String
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

    /// Create a new user.
    func create(req: Request) async throws -> User {
        let setupUser = try req.content.decode(SetupUser.self)

        let user = User(setupUser)

        try await user.create(on: req.db)

        return user
    }

    // func delete(req: Request) async throws -> HTTPStatus {
    //     let authenticationPlaceholder = try req.content.decode(UserAuthenticationPlaceholder.self)

    //     guard let user = try await User.find(authenticationPlaceholder.userID, on: req.db) else {
    //         throw Abort(.notFound, reason: "User not found.")
    //     }

    //     if let existingConfession = try await user.$confession.get(on: req.db) {
    //         try await existingConfession.delete(on: req.db)
    //     }

    //     return .ok
    // }
}
