import Fluent
import Vapor

final class Confession: Model, Content {
    static let schema = "confessions"

    @ID(key: .id)
    var id: UUID?

    /// The confessing user. This information is public; who they're confessing to is not.
    @Parent(key: "user_id")
    var user: User

    /// The encrypted blob of the public key for the confession.
    @Field(key: "blob")
    var blob: String

    /// When the confession can be replaced with a new one.
    @Field(key: "expiry")
    var expiry: Date

    init() { }

    init(id: UUID? = nil, blob: String) {
        self.id = id
        self.blob = blob
    }
}
