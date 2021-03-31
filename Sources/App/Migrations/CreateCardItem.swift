//
//  CreateCardItem.swift
//  
//
//  Created by Keith Weiss on 3/30/21.
//

import Fluent
import Vapor

struct CreateCardItem: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CardItem.schema)
            .id()
            .field("isInternetRequired", .bool, .required)
            .field("isPinned", .bool, .required)
            .field("purchaseRequirement", .string, .required)
            .field("category", .string, .required)
            .field("title", .string, .required)
            .field("callToAction", .string, .required)
            .field("deleted_at", .datetime)
            .field("user_id", .uuid, .references(User.schema, "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CardItem.schema).delete()
    }
}

