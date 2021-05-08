//
//  Team.swift
//  
//
//  Created by Keith Weiss on 2/26/21.
//

import Fluent
import Vapor

final class Team: Model, Content {
    static let schema = "teams"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Children(for: \.$team)
    var cardItems: [CardItem]
    
    @Siblings(
        through: TeamUserPivot.self,
        from: \.$team,
        to: \.$user)
    var users: [User]
    
    init() { }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

