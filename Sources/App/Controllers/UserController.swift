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
        
        let passwordProtected = users.grouped(User.authenticator())
        passwordProtected.post("login", use: loginHandler)
        
        let tokenProtected = users.grouped(UserToken.authenticator())
            .grouped(User.guardMiddleware())
        tokenProtected.get(use: getAllHandler)
        tokenProtected.get("logout", use: logoutHandler)
        tokenProtected.get("me", "full") { req -> User in
            try req.auth.require(User.self)
        }
        tokenProtected.get("me") { req -> User.Public in
            try req.auth.require(User.self).toPublic()
        }
        
        tokenProtected.group(":userID") { protected in
            protected.get(use: getHandler)
            protected.get("teams", use: getTeamsHandler)
            protected.get("images", use: getImagesHandler)
            protected.post("team", ":teamID", use: addTeamsHandler)
            protected.patch("restore", use: restoreHandler)
            protected.delete(use: deleteHandler)
            protected.delete("hard", use: deleteHardHandler)
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
    
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db).all().mapEach { $0.toPublic() }
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
    
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        
        let user = try User(
            name: create.name,
            username: create.username,
            email: create.email,
            passwordHash: Bcrypt.hash(create.password)
        )
        
        return user.save(on: req.db)
            .map { user.toPublic() }
    }
    
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<UserToken> {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        return token.save(on: req.db)
            .map { token }
    }
    
    
    func logoutHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        req.auth.logout(User.self)
        
        return UserToken.query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()
            .flatMap { tokens in
                return tokens.delete(force: true, on: req.db)
                    .transform(to: .resetContent)
            }
    }
    
    
    func restoreHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let uuidString = req.parameters.get("userID"),
              let uuid = UUID(uuidString: uuidString) else { throw Abort(.badRequest) }
        return User.query(on: req.db)
            .filter(\.$id == uuid)
            .withDeleted()
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap {
                $0.restore(on: req.db)
                    .transform(to: .resetContent)
            }
    }
    
    
    func deleteHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                guard user.username != "admin" else { return req.eventLoop.future(.unauthorized) }
                
                if let authUser = req.auth.get(User.self),
                   authUser.id == user.id {
                    req.auth.logout(User.self)
                }
                
                return user.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    
    func deleteHardHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        guard user.username == "admin" else { throw Abort(.unauthorized) }
        
        guard let uuidString = req.parameters.get("userID"),
              let uuid = UUID(uuidString: uuidString) else { throw Abort(.badRequest) }
        
        return User.query(on: req.db)
            .filter(\.$id == uuid)
            .withDeleted()
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                guard user.username != "admin" else { return req.eventLoop.future(.unauthorized) }
                
                return user.delete(force: true, on: req.db)
                    .transform(to: .noContent)
            }
    }
}
