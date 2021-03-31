//
//  CreateCardAction.swift
//  
//
//  Created by Keith Weiss on 3/30/21.
//

import Fluent
import Vapor

struct CreateCardAction: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CardAction.schema)
            .id()
            .field("type", .string, .required)
            .field("baseOrResourceURL", .string, .required)
            .field("safari", .string, .required)
            .field("size", .dictionary(of: .int), .required)
            .field("version", .int, .required)
            .field("deleted_at", .datetime)
            .field("user_id", .uuid, .references(User.schema, "id", onDelete: .cascade))
            .field("card_item_id", .uuid, .references(CardItem.schema, "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CardAction.schema).delete()
    }
}
