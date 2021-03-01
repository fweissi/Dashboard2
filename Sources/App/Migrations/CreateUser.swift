//
//  CreateUser.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field("name", .string, .required)
            .field("username", .string, .required)
            .field("email", .string, .required)
            .field("password", .string, .required)
            .unique(on: "username", name: "no_duplicate_usernames")
            .unique(on: "email", name: "no_duplicate_emails")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}
