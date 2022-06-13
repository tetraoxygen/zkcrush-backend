import Fluent
import Vapor

final class Reply: Model, Content {
    static let schema = "replies"

    @ID(key: .id)
    var id: UUID?

    /// The replying user. This information is public; who they're replying to is not.
    @Parent(key: "user_id")
    var user: User

    /// The encrypted blob of the 'yes' reply to the confession.
    @Field(key: "blob")
    var blob: String

    /// When the reply expires.
    @Field(key: "expiry")
    var expiry: Date

    init() { }

    init(id: UUID? = nil, blob: String) {
        self.id = id
        self.blob = blob
    }
}
