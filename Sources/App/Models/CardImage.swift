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
    
    @Field(key: "title")
    var title: String
    
    @Parent(key: "user_id")
    var user: User
    
    var publicUser: User.Public {
        user.toPublic()
    }
    
    init() { }
    
    init?(id: UUID? = nil, title: String, user: User) throws {
        self.id = id
        self.title = title
        self.$user.id = try user.requireID()
    }
}


extension CardImage {
    struct Create: Content {
        var title: String
    }
}
