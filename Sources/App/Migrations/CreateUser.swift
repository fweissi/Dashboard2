//
//  CreateUser.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Fluent
import Vapor

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field("name", .string, .required)
            .field("username", .string, .required)
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("deleted_at", .datetime)
            .unique(on: "username", name: "no_duplicate_usernames")
            .unique(on: "email", name: "no_duplicate_emails")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}


struct UserMigrationSeed: Migration {
    func prepare(on db: Database) -> EventLoopFuture<Void> {
        [
            User(
                name: "Administrator",
                username: "admin",
                email: "admin@brandwise.com",
                passwordHash: try! Bcrypt.hash(Environment.get("ADMIN_PASSWORD")!)
            )
        ].create(on: db)
    }

    func revert(on db: Database) -> EventLoopFuture<Void> {
        User.query(on: db).delete()
    }
}
