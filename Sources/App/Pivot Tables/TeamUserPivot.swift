//
//  TeamUserPivot.swift
//  
//
//  Created by Keith Weiss on 2/26/21.
//

import Fluent
import Foundation

final class TeamUserPivot: Model {
    static let schema = "team-user-pivot"
    
    @ID
    var id: UUID?
    
    @Parent(key: "team_id")
    var team: Team
    
    @Parent(key: "user_id")
    var user: User
    
    init() {}
    
    init(
        id: UUID? = nil,
        team: Team,
        user: User
    ) throws {
        self.id = id
        self.$team.id = try team.requireID()
        self.$user.id = try user.requireID()
    }
}
