//
//  TeamController.swift
//  
//
//  Created by Keith Weiss on 2/26/21.
//

import Fluent
import Vapor

struct TeamController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let teams = routes.grouped("api", "teams")
        teams.get(use: getAllHandler)
        teams.get("cards", use: getAllWithCardItemsHandler)
        
        let protected = teams
            .grouped(UserToken.authenticator())
            .grouped(User.guardMiddleware())
        
        
        protected.get("users","private", use: getAllWithUsersHandler)
        protected.post(use: createHandler)
        
        protected.group(":teamID") { team in
            team.get("users", use: getUsersHandler)
            team.get(use: getHandler)
            team.post("user", ":userID", use: addUsersHandler)
            team.post("card", ":cardID", use: addCardItemsHandler)
            team.post("save", use: postCardItemsHandler)
            team.delete("user", ":userID", use: deleteUsersHandler)
            team.delete("card", ":cardID", use: deleteCardItemsHandler)
        }
    }
    
    
    func addUsersHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let teamQuery = Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return teamQuery.and(userQuery)
            .flatMap { team, user in
                team
                    .$users
                    .attach(user, on: req.db)
                    .transform(to: .created)
            }
    }
    
    
    func addCardItemsHandler(_ req: Request) throws -> EventLoopFuture<CardItem> {
        let teamQuery = Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let cardItemQuery = CardItem.find(req.parameters.get("cardID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return teamQuery.and(cardItemQuery)
            .flatMap { team, cardItem in
                cardItem.$team.id = team.id
                return cardItem.save(on: req.db).map { cardItem }
            }
    }
    
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Team]> {
        Team.query(on: req.db).all()
    }
    
    
    func getAllWithUsersHandler(_ req: Request) throws -> EventLoopFuture<[Team]> {
        Team.query(on: req.db).with(\.$users).all()
    }
    
    
    func getAllWithCardItemsHandler(_ req: Request) throws -> EventLoopFuture<[Team]> {
        Team.query(on: req.db).with(\.$cardItems) { cardItem in
            cardItem.with(\.$links)
        }.all()
    }
    
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Team> {
        Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    
    func getUsersHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { team in
                team.$users.get(on: req.db).flatMap { users in
                    req.eventLoop.future( users.map { $0.toPublic() })
                }
            }
    }
    
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Team> {
        let team = try req.content.decode(Team.self)
        return team.save(on: req.db).map { team }
    }
    
    
    func postCardItemsHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let jsonObject = try req.content.decode(CardInput.self, using: JSONDecoder())
        guard let uuidString = req.parameters.get("teamID"),
              let teamID = UUID(uuidString: uuidString) else { throw Abort(.badRequest) }
        
        return CardItem.query(on: req.db)
            .join(Team.self, on: \CardItem.$team.$id == \Team.$id)
            .filter(Team.self, \.$id == teamID)
            .all()
            .flatMapEach(on: req.eventLoop) { card -> EventLoopFuture<CardItem> in
                card.$team.id = nil
                return card.save(on: req.db).map { card }
            }
            .flatMapThrowing { _ in
                return jsonObject.cardIDs.compactMap({ cardUUID -> EventLoopFuture<CardItem?> in
                    guard let cardID = UUID(uuidString: cardUUID) else { return req.eventLoop.future(nil) }
                    
                    return CardItem.find(cardID, on: req.db)
                        .flatMap { card in
                            guard let card = card else { return req.eventLoop.future(nil) }
                            
                            card.$team.id = teamID
                            return card.save(on: req.db).map { card }
                        }
                })
            }
            .transform(to: .noContent)
    }
    
    struct CardInput: Codable {
        let cardIDs: [String]
    }
    
    
    func deleteUsersHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let teamQuery = Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return teamQuery.and(userQuery)
            .flatMap { team, user in
                team
                    .$users
                    .detach(user, on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    
    func deleteCardItemsHandler(_ req: Request) throws -> EventLoopFuture<CardItem> {
        let teamQuery = Team.find(req.parameters.get("teamID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let cardItemQuery = CardItem.find(req.parameters.get("cardID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return teamQuery.and(cardItemQuery)
            .flatMap { team, cardItem in
                cardItem.$team.id = nil
                return cardItem.save(on: req.db).map { cardItem }
            }
    }
}
