//
//  UserController.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Crypto
import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        users.post(use: createHandler)
        
        let protected = users.grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())
        protected.get(use: getAllHandler)
        protected.get("me") { req -> String in
            try req.auth.require(User.self).name
        }
        
        protected.group(":userID") { user in
            user.get(use: getHandler)
            user.get("teams", use: getTeamsHandler)
            user.get("images", use: getImagesHandler)
            user.post("team", ":teamID", use: addTeamsHandler)
            user.patch("restore", use: restoreHandler)
            user.delete(use: deleteHandler)
            user.delete("hard", use: deleteHardHandler)
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
        try User.validate(content: req)
        user.password = try Bcrypt.hash(user.password)
        return user.save(on: req.db).map { user }
    }
    
    
    func restoreHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let uuidString = req.parameters.get("userID"),
              let uuid = UUID(uuidString: uuidString) else { throw Abort(.badRequest) }
        return User.query(on: req.db).filter(\.$id == uuid).withDeleted().first().unwrap(or: Abort(.notFound))
            .flatMap { $0.restore(on: req.db) }
            .transform(to: .resetContent)
    }
    
    
    func deleteHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                guard user.username != "admin" else { return req.eventLoop.future(.unauthorized) }
                
                return user.delete(on: req.db)
                    .transform(to: .resetContent)
            }
    }
    
    
    func deleteHardHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let uuidString = req.parameters.get("userID"),
              let uuid = UUID(uuidString: uuidString) else { throw Abort(.badRequest) }
        return User.query(on: req.db).filter(\.$id == uuid).withDeleted().first().unwrap(or: Abort(.notFound))
            .flatMap { user in
                guard user.username != "admin" else { return req.eventLoop.future(.unauthorized) }
                
                return user.delete(on: req.db)
                    .transform(to: .resetContent)
            }
    }
}
