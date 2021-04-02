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
                    savedCard.isInternetRequired = item.isInternetRequired
                    savedCard.isPinned = item.isPinned
                    savedCard.purchaseRequirement = item.purchaseRequirement
                    savedCard.category = item.category
                    savedCard.title = item.title
                    savedCard.callToAction = item.callToAction
                    
                    return savedCard.update(on: req.db).map {
                        let links = item.links
                        let _ = links.compactMap { link in
                            CardAction.find(link.id, on: req.db).map { savedLink -> EventLoopFuture<CardAction?> in
                                if let savedLink = savedLink {
                                    savedLink.linkType = link.linkType
                                    savedLink.baseOrResourceURL = link.baseOrResourceURL
                                    savedLink.embeddedHTML = link.embeddedHTML
                                    savedLink.safariOption = link.safariOption ?? .modal
                                    savedLink.size = link.size
                                    savedLink.version = link.version
                                    
                                    return savedLink.update(on: req.db).map { savedLink }
                                }
                                else {
                                    guard let cardAction = try? CardAction(from: link, with: savedCard.requireID())
                                    else { return req.db.eventLoop.future(error: Abort(.badRequest)) }
                                    
                                    return cardAction.create(on: req.db).map { cardAction }
                                }
                            }
                        }
                        
                        return savedCard
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
        .transform(to: HTTPStatus.ok)
    }
    
    
    func deleteHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let actionsDelete = CardAction.query(on: req.db).all().flatMap({ $0.delete(force: true, on: req.db)})
        let itemsDelete = CardItem.query(on: req.db).all().flatMap({ $0.delete(force: true, on: req.db)})
        return actionsDelete.and(itemsDelete).transform(to: HTTPStatus.ok)
    }
}
