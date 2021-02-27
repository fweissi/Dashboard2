import Fluent
import Vapor

struct CardController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let cards = routes.grouped("cards")
        cards.get(use: getAllHandler)
        cards.post(use: createHandler)
        
        cards.group(":cardID") { card in
            card.delete(use: deleteHandler)
        }
    }
    
    
    func getAllHandler(req: Request) throws -> EventLoopFuture<[Card]> {
        Card.query(on: req.db).all()
    }
    
    
    func createHandler(req: Request) throws -> EventLoopFuture<Card> {
        let card = try req.content.decode(Card.self)
        if card.start == nil {
            card.start = Date.distantPast
        }
        if card.end == nil {
            card.end = Date.distantFuture
        }
        return card.save(on: req.db).map { card }
    }
    
    
    func deleteHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        Card.find(req.parameters.get("cardID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}

