//
//  UserController.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Vapor

struct UserController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let usersRoute = routes.grouped("api", "users")
    usersRoute.post(use: createHandler)
  }

  func createHandler(_ req: Request)
    throws -> EventLoopFuture<User> {
    let user = try req.content.decode(User.self)
    return user.save(on: req.db).map { user }
  }
}
