//
//  User.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Crypto
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    @Children(for: \.$user)
    var cardImages: [CardImage]
    
    @Siblings(
        through: TeamUserPivot.self,
        from: \.$user,
        to: \.$team)
    var teams: [Team]
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, email: String, password: String) {
        self.name = name
        self.username = username
        self.email = email
        self.password = password
    }
}
