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
        protected.delete(use: deleteHandler)
    }
    
    
    func getHandler(req: Request) throws -> EventLoopFuture<[CardItem]> {
        CardItem.query(on: req.db).with(\.$links).all()
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
                    cards.map { item -> EventLoopFuture<CardItem> in
                        guard let cardItem = try? CardItem(from: item, with: user.requireID()) else { fatalError() }
                        let links = item.links
                        return cardItem.create(on: database).map {
                            let _ = links.map { link -> EventLoopFuture<CardAction> in
                                guard let cardAction = try? CardAction(from: link, with: cardItem.requireID()) else { fatalError() }
                                return cardAction.create(on: req.db).map { cardAction }
                            }
                            return cardItem
                        }
                    }
                }
                .transform(to: HTTPStatus.ok)
        }
    }
    
    
    func deleteHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let actionsDelete = CardAction.query(on: req.db).all().flatMap({ $0.delete(force: true, on: req.db)})
        let itemsDelete = CardItem.query(on: req.db).all().flatMap({ $0.delete(force: true, on: req.db)})
        return actionsDelete.and(itemsDelete).transform(to: HTTPStatus.ok)
    }
}
