import Fluent

struct CreateCard: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("cards")
            .id()
            .field("isBanner", .bool, .required)
            .field("title", .string, .required)
            .field("details", .string, .required)
            .field("assetID", .string)
            .field("assetPath", .string)
            .field("start", .datetime)
            .field("end", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("cards").delete()
    }
}
