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
    
    
    func createHandler(req: Request) throws -> EventLoopFuture<[CardItem]> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // decodes Hello struct using custom decoder
        let dashboard = try req.content.decode(Dashboard.self, using: decoder)
        let user = try req.auth.require(User.self)
        let cards = dashboard.items
        for card in cards {
            let cardItem = try CardItem(
                id: nil,
                isInternetRequired: card.isInternetRequired,
                isPinned: card.isPinned,
                purchaseRequirement: card.purchaseRequirement,
                category: card.category,
                title: card.title,
                callToAction: card.callToAction,
                userID: user.requireID())
            
            let _ = cardItem.save(on: req.db)
        }
        
        return CardItem.query(on: req.db).with(\.$links).all()
    }
}
