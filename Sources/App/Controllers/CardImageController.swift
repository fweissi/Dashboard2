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
        let cardImages = routes.grouped("api", "images")
        cardImages.get(use: getAllHandler)
        cardImages.post(use: createHandler)
        
        cardImages.group(":imageID") { cardImage in
            cardImage.get("user", use: getUserHandler)
            cardImage.patch(use: updateHandler)
            cardImage.delete(use: deleteHandler)
        }
    }
    
    
    func getAllHandler(req: Request) throws -> EventLoopFuture<[CardImage]> {
        CardImage.query(on: req.db).all()
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
        let cardImage = CardImage(title: data.title, userID: data.userID)
        return cardImage.save(on: req.db).map { cardImage }
    }
    
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<CardImage> {
        let updateData =
            try req.content.decode(CreateCardImageData.self)
        return CardImage
            .find(req.parameters.get("imageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { cardImage in
                cardImage.title = updateData.title
                cardImage.$user.id = updateData.userID
                return cardImage.save(on: req.db).map {
                    cardImage
                }
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
    let userID: UUID
}


