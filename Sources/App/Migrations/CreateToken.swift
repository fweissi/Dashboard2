//
//  CreateToken.swift
//  
//
//  Created by Keith Weiss on 3/2/21.
//

import Fluent

struct CreateUserToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(UserToken.schema)
            .id()
            .field("value", .string, .required)
            .field("user_id", .uuid, .references(User.schema, "id"))
            .unique(on: "value")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(UserToken.schema).delete()
    }
}
