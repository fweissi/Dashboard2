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
            .field("team_id", .uuid, .required, .references(Team.schema, "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .create()
    }
    
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TeamUserPivot.schema).delete()
    }
}


struct TeamUserPivotMigrationSeed: Migration {
    func prepare(on db: Database) -> EventLoopFuture<Void> {
        let teamQuery = Team.query(on: db).first()
        let userQuery = User.query(on: db).first()
        return teamQuery.and(userQuery)
            .flatMap { team, user in
                if let team = team,
                   let user = user {
                    let _ = team
                        .$users
                        .attach(user, on: db)
                }
                return db.eventLoop.makeSucceededVoidFuture()
            }
    }

    func revert(on db: Database) -> EventLoopFuture<Void> {
        TeamUserPivot.query(on: db).delete()
    }
}

