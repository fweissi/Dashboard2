//
//  UserMiddleware.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import FluentKit
import Vapor
struct UserMiddleware: ModelMiddleware {
    func create(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        // The model can be altered here before it is created.
        model.name = model.name.capitalized
        model.username = model.username.lowercased()
        return next.create(model, on: db).map {
            // Once the planet has been created, the code
            // here will be executed.
            print ("User \(model.username) was created")
        }
    }
    
    
    func softDelete(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        guard model.username != "admin" else {
            print("DENIED /admin user not soft deleted.")
            return db.eventLoop.future()
        }
        
        return next.softDelete(model, on: db)
    }
    
    func delete(model: User, force: Bool, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        guard model.username != "admin" else {
            print("DENIED /admin user not deleted.")
            return db.eventLoop.future()
        }
        
        return next.delete(model, force: force, on: db)
    }
}
