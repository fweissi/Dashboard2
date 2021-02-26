//
//  UserController.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        users.get(use: getAllHandler)
        users.post(use: createHandler)
        
        users.group(":userID") { user in
            user.get(use: getHandler)
        }
    }
    
    
    func getAllHandler(_ req: Request)
    throws -> EventLoopFuture<[User]> {
        User.query(on: req.db).all()
    }
    
    
    func getHandler(_ req: Request)
    throws -> EventLoopFuture<User> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
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
