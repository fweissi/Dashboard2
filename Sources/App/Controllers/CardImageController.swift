//
//  CardImageController.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Fluent
import Vapor

struct CardImageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("images")
        todos.get(use: index)
        todos.post(use: create)
        todos.group(":imagesID") { todo in
            todo.delete(use: delete)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[Todo]> {
        return Todo.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<Todo> {
        let todo = try req.content.decode(Todo.self)
        return todo.save(on: req.db).map { todo }
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Todo.find(req.parameters.get("imagesID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}


