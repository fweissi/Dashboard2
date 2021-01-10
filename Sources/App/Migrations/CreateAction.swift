import Fluent

struct CreateAction: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("actions")
            .id()
            .field("card_id", .uuid, .required, .references("cards", "id"))
            .field("type", .string, .required)
            .field("displayOption", .string, .required)
            .field("displayWidth", .int16)
            .field("displayHeight", .int16)
            .field("responseOption", .string, .required)
            .field("assetID", .string)
            .field("urlPath", .string)
            .field("embeddedHTML", .string)
            .field("start", .datetime)
            .field("end", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("actions").delete()
    }
}
