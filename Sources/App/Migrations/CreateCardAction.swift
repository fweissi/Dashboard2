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
            .field("baseOrResourceURL", .string)
            .field("embeddedHTML", .string)
            .field("safari", .string, .required)
            .field("size", .dictionary(of: .int), .required)
            .field("version", .int, .required)
            .field("card_item_id", .uuid, .required, .references(CardItem.schema, "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CardAction.schema).delete()
    }
}
