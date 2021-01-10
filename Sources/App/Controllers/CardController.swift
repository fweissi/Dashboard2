import Fluent
import Vapor

struct CardController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let cards = routes.grouped("cards")
        cards.get(use: index)
        cards.post(use: create)
        cards.group(":cardID") { card in
            card.delete(use: delete)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[Card]> {
        return Card.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<Card> {
        let card = try req.content.decode(Card.self)
        if card.start == nil {
            card.start = Date.distantPast
        }
        if card.end == nil {
            card.end = Date.distantFuture
        }
        return card.save(on: req.db).map { card }
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Card.find(req.parameters.get("cardID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}

