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
    
    @Field(key: "corp_id")
    var corpID: Int
    
    @Children(for: \.$team)
    var cardItems: [CardItem]
    
    @Siblings(
        through: TeamUserPivot.self,
        from: \.$team,
        to: \.$user)
    var users: [User]
    
    init() { }
    
    init(id: UUID? = nil, name: String, corpID: Int) {
        self.id = id
        self.name = name
        self.corpID = corpID
    }
}


//  Displaying Users but hiding sensative information
extension Team {
    struct Public: Content {
        let id: UUID?
        let name: String
        let hasCards: Bool
    }
    
    func toPublic(on database: Database) -> Team.Public {
        Public(id: id, name: name, hasCards: cardItems.count > 0)
    }
}

