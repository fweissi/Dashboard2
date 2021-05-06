//
//  DashboardController.swift
//  
//
//  Created by Keith Weiss on 3/30/21.
//


import Fluent
import Vapor

struct DashboardController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped("api", "dashboard")
            .grouped(UserToken.authenticator())
            .grouped(User.guardMiddleware())
        protected.get(use: getHandler)
        protected.post(use: createHandler)
        protected.put(use: updateHandler)
        protected.delete(use: deleteHandler)
        
        protected.group(":cardID") { protected in
            protected.delete(use: deleteCardHandler)
        }
    }
    
    
    func getHandler(req: Request) throws -> EventLoopFuture<CardItem.Dashboard> {
        CardItem.query(on: req.db).with(\.$links).all().map({ cards in
            return CardItem.Dashboard(items: cards)
        })
    }
    
    
    func createHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // decodes Hello struct using custom decoder
        let dashboard = try req.content.decode(Dashboard.self, using: decoder)
        let user = try req.auth.require(User.self)
        let cards = dashboard.items
        
        return req.db.transaction { database -> EventLoopFuture<HTTPStatus> in
            let actionsDelete = CardAction.query(on: database).all().flatMap({ $0.delete(force: true, on: database)})
            let itemsDelete = CardItem.query(on: database).all().flatMap({ $0.delete(force: true, on: database)})
            return actionsDelete.and(itemsDelete)
                .map { _, _ in
                    cards.compactMap { item -> EventLoopFuture<CardItem>? in
                        guard let cardItem = try? CardItem(from: item, with: user.requireID()) else { return nil }
                        let links = item.links
                        return cardItem.create(on: database).map {
                            let _ = links.compactMap { link -> EventLoopFuture<CardAction>? in
                                guard let cardAction = try? CardAction(from: link, with: cardItem.requireID()) else { return nil }
                                return cardAction.create(on: req.db).map { cardAction }
                            }
                            return cardItem
                        }
                    }
                }
                .transform(to: HTTPStatus.ok)
        }
    }
    
    
    func updateHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // decodes Hello struct using custom decoder
        let dashboard = try req.content.decode(Dashboard.self, using: decoder)
        let user = try req.auth.require(User.self)
        let cards = dashboard.items
        
        return cards.compactMap { item in
            CardItem.find(item.id, on: req.db).flatMap { savedCard -> EventLoopFuture<CardItem?> in
                if let savedCard = savedCard {
                    return savedCard.delete(on: req.db).flatMap { _ -> EventLoopFuture<CardItem?> in
                        guard let cardItem = try? CardItem(from: item, with: user.requireID())
                        else { return req.db.eventLoop.future(error: Abort(.badRequest)) }
                        
                        let links = item.links
                        return cardItem.create(on: req.db).map {
                            let _ = links.compactMap { link -> EventLoopFuture<CardAction>? in
                                guard let cardAction = try? CardAction(from: link, with: cardItem.requireID())
                                else { return req.db.eventLoop.future(error: Abort(.badRequest)) }
                                
                                return cardAction.create(on: req.db).map { cardAction }
                            }
                            
                            return cardItem
                        }
                    }
                }
                else {
                    guard let cardItem = try? CardItem(from: item, with: user.requireID())
                    else { return req.db.eventLoop.future(error: Abort(.badRequest)) }
                    
                    let links = item.links
                    return cardItem.create(on: req.db).map {
                        let _ = links.compactMap { link -> EventLoopFuture<CardAction>? in
                            guard let cardAction = try? CardAction(from: link, with: cardItem.requireID())
                            else { return req.db.eventLoop.future(error: Abort(.badRequest)) }
                            
                            return cardAction.create(on: req.db).map { cardAction }
                        }
                        
                        return cardItem
                    }
                }
            }
        }
        .flatten(on: req.eventLoop)
        .transform(to: HTTPStatus.noContent)
    }
    
    
    func deleteHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return CardItem.query(on: req.db).all().flatMap({ $0.delete(force: true, on: req.db)})
            .transform(to: HTTPStatus.noContent)
    }
    
    
    func deleteCardHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return CardItem.find(req.parameters.get("cardID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap({ $0.delete(force: true, on: req.db)})
            .transform(to: HTTPStatus.noContent)
    }
}
