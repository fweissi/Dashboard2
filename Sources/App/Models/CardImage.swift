//
//  CardImage.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Fluent
import Vapor

final class CardImage: Model, Content {
    static let schema = "card_images"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "uri")
    var uri: String
    
    @Field(key: "key")
    var key: String
    
    @Parent(key: "user_id")
    var user: User
    
    var publicUser: User.Public {
        user.toPublic()
    }
    
    init() { }
    
    init?(id: UUID? = nil, uri: String, key: String, user: User) throws {
        self.id = id
        self.uri = uri
        self.key = key
        self.$user.id = try user.requireID()
    }
}


extension CardImage {
    struct Create: Content {
        var key: String
    }
}
