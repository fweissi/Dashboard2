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
            CardItem.query(on: database).all().flatMap({ $0.delete(force: true, on: database)}).map {
                cards.map { (item) -> EventLoopFuture<CardItem> in
                    guard let cardItem = try? CardItem(from: item, with: user.requireID()) else { fatalError() }
                    return cardItem.create(on: database).map {
                        let _ = item.links.compactMap { link -> EventLoopFuture<CardAction>? in
                            if let cardAction = try? CardAction(from: link, with: cardItem.requireID()) {
                                return cardAction.create(on: database).map({ cardAction })
                            }
                            else {
                                return nil
                            }
                        }
                        return cardItem
                    }
                }
            }
            .transform(to: HTTPStatus.ok)
        }
    }
}
