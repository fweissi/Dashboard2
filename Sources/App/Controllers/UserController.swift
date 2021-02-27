//
//  UserController.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        users.get(use: getAllHandler)
        users.post(use: createHandler)
        
        users.group(":userID") { user in
            user.get(use: getHandler)
            user.get("teams", use: getTeamsHandler)
            user.get("images", use: getImagesHandler)
            user.post("team", ":teamID", use: addTeamsHandler)
        }
    }
    
    
    func addTeamsHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let teamQuery = Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return userQuery.and(teamQuery)
            .flatMap { user, team in
                user
                    .$teams
                    .attach(team, on: req.db)
                    .transform(to: .created)
            }
    }
    
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User]> {
        User.query(on: req.db).all()
    }
    
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<User> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    
    func getTeamsHandler(_ req: Request) throws -> EventLoopFuture<[Team]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$teams.get(on: req.db)
            }
    }
    
    func getImagesHandler(_ req: Request) throws -> EventLoopFuture<[CardImage]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$cardImages.get(on: req.db)
            }
    }
    
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<User> {
        let user = try req.content.decode(User.self)
        return User.query(on: req.db).filter(\.$username == user.username.lowercased()).first()
            .flatMap { existingUser in
                if let _ = existingUser {
                    return req.eventLoop.future(error: Abort(.badRequest, reason: "Username is already in use."))
                }
                else {
                    return user.save(on: req.db).map { user }
                }
            }
    }
}
