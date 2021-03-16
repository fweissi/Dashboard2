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
            .grouped(UserToken.authenticator())
            .grouped(User.guardMiddleware())
        protected.get(use: getAllHandler)
        protected.post(use: createHandler)
        protected.post("upload", use: uploadHandler)
        
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
        let image = try req.content.decode(CardImage.Create.self)
        let user = try req.auth.require(User.self)
        guard let cardImage = try CardImage(uri: "", key: image.key, user: user)
        else {
            throw Abort(.notFound)
        }
        return cardImage.save(on: req.db).map { cardImage }
    }
    
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<CardImage> {
        let updateData = try req.content.decode(CreateCardImageData.self)
        guard let uuid: UUID = try req.auth.require(User.self).id else { throw Abort(.badRequest) }
        
        return CardImage
            .find(req.parameters.get("imageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { cardImage in
                cardImage.key = updateData.key
                cardImage.$user.id = uuid
                return cardImage.save(on: req.db).map { cardImage }
            }
    }
    
    
    func uploadHandler(_ req: Request) throws -> EventLoopFuture<String> {
        let key = try req.query.get(String.self, at: "key")
        let user = try req.auth.require(User.self)
        
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .flatMap { data in
                req.fs.upload(key: key, data: Data(buffer: data)).flatMap { uri in
                    guard let cardImage = try? CardImage(uri: uri, key: key, user: user)
                    else { fatalError() }
                    return cardImage.save(on: req.db).map { uri }
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
    let key: String
}


