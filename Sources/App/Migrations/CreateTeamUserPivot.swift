//
//  CreateTeamUserPivot.swift
//  
//
//  Created by Keith Weiss on 2/26/21.
//

import Fluent

struct CreateTeamUserPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TeamUserPivot.schema)
            .id()
            .field("teamID", .uuid, .required, .references(Team.schema, "id", onDelete: .cascade))
            .field("userID", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .create()
    }
    
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TeamUserPivot.schema).delete()
    }
}
