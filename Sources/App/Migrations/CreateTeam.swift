//
//  File.swift
//  
//
//  Created by Keith Weiss on 2/26/21.
//

import Fluent

struct CreateTeam: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Team.schema)
            .id()
            .field("name", .string, .required)
            .field("corp_id", .int, .required)
            .unique(on: "corp_id", name: "no_duplicate_corp_ids")
            .unique(on: "name", name: "no_duplicate_names")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Team.schema).delete()
    }
}


struct TeamMigrationSeed: Migration {
    func prepare(on db: Database) -> EventLoopFuture<Void> {
        [
            Team(name: "Brandwise", corpID: 1)
        ].create(on: db)
    }

    func revert(on db: Database) -> EventLoopFuture<Void> {
        Team.query(on: db).delete()
    }
}
