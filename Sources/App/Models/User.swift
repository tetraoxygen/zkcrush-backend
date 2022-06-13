import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "replies"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    /// The user's public key, used for encrypting confessions to them.
    @Field(key: "global_key")
    var globalKey: String

    /// The last time the user confessed or replied to a confession.
    @Field(key: "last_confession")
    var lastConfession: Date

    /// The user's current confession (if any).
    @OptionalChild(for: \.$user)
    var confession: Confession?

    /// The user's current reply (if any).
    @OptionalChild(for: \.$user)
    var reply: Reply?

    init() { }

    init(id: UUID? = nil, name: String, globalKey: String) {
        self.id = id
        self.name = name
        self.globalKey = globalKey
    }
}
