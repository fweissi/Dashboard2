//
//  CreateCardImage.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Fluent

struct CreateCardImage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("card_images")
            .id()
            .field("title", .string, .required)
            .field("userID", .uuid, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("card_images").delete()
    }
}

