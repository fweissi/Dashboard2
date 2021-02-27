//
//  TeamController.swift
//  
//
//  Created by Keith Weiss on 2/26/21.
//

import Fluent
import Vapor

struct TeamController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let teams = routes.grouped("api", "teams")
        
        teams.get(use: getAllHandler)
        teams.post(use: createHandler)
        
        teams.group(":teamID") { team in
            team.get("users", use: getUsersHandler)
            team.get(use: getHandler)
            team.post("user", ":userID", use: addUsersHandler)
        }
    }
    
    
    func addUsersHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let teamQuery = Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return teamQuery.and(userQuery)
            .flatMap { team, user in
                team
                    .$users
                    .attach(user, on: req.db)
                    .transform(to: .created)
            }
    }
    
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Team]> {
        Team.query(on: req.db).all()
    }
    
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Team> {
        Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    
    func getUsersHandler(_ req: Request) throws -> EventLoopFuture<[User]> {
        Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { team in
                team.$users.get(on: req.db)
            }
    }
    
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Team> {
        let team = try req.content.decode(Team.self)
        return team.save(on: req.db).map { team }
    }
}
