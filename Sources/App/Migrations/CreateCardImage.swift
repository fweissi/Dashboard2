//
//  CreateCardImage.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Fluent

struct CreateCardImage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CardImage.schema)
            .id()
            .field("title", .string, .required)
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CardImage.schema).delete()
    }
}

