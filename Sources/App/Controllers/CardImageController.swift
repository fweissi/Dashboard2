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
        let protected = routes.grouped("api", "images")
            .grouped(User.PasswordAuthenticator())
            .grouped(User.TokenAuthenticator())
            .grouped(User.guardMiddleware())
        protected.get(use: getAllHandler)
        protected.post(use: createHandler)
        protected.get(use: getAllHandler)
        
        protected.group(":imageID") { protected in
            protected.get("user", use: getUserHandler)
            protected.patch(use: updateHandler)
            protected.delete(use: deleteHandler)
        }
    }
    
    
    func getAllHandler(req: Request) throws -> EventLoopFuture<[CardImage]> {
        CardImage.query(on: req.db).with(\.$user).all()
    }
    
    
    func getUserHandler(_ req: Request) throws -> EventLoopFuture<User> {
        CardImage.find(req.parameters.get("imageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$user.get(on: req.db)
            }
    }
    
    
    func createHandler(req: Request) throws -> EventLoopFuture<CardImage> {
        let data = try req.content.decode(CreateCardImageData.self)
        let verifiedUser = try req.auth.require(User.self)
        return User.query(on: req.db)
            .filter(\.$username == verifiedUser.username)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { user -> EventLoopFuture<CardImage> in
                do {
                    let userID = try user.requireID()
                    let cardImage = CardImage(title: data.title, userID: userID)
                    return cardImage.save(on: req.db).map { cardImage }
                }
                catch {
                    fatalError()
                }
            }
    }
    
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<CardImage> {
        let updateData =
            try req.content.decode(CreateCardImageData.self)
        guard let uuid: UUID = try req.auth.require(User.self).id else { throw Abort(.badRequest) }
        
        return CardImage
            .find(req.parameters.get("imageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { cardImage in
                cardImage.title = updateData.title
                cardImage.$user.id = uuid
                return cardImage.save(on: req.db).map { cardImage }
            }
    }
    
    
    func deleteHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        CardImage.find(req.parameters.get("imageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}


struct CreateCardImageData: Content {
    let title: String
}


