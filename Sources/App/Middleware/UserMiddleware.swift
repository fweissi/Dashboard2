//
//  UserMiddleware.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import FluentKit
import Vapor

//struct UserUniqueMiddleware: Middleware {
//
//   func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
//
//    User.query(on: db)
//        .filter(\.$username, .equal, model.username.lowercased())
//        .first()
//        .flatMap { existingUser in
//            guard existingUser == nil else { throw Abort(.badRequest, reason: "Username is already in use.") }
//    guard let user = request.auth.get(User.self), user.role == .admin else {
//        return request.eventLoop.future(error: Abort(.unauthorized))
//    }
//
//    return next.respond(to: request)
//    }
//
//}


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
}
