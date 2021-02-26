import Fluent
import Vapor

struct ActionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let actions = routes.grouped("actions")
        actions.get(use: index)
        actions.post(use: create)
        actions.group(":actionID") { action in
            action.delete(use: delete)
        }
    }
    
    
    func index(req: Request) throws -> EventLoopFuture<[Action]> {
        return Action.query(on: req.db).all()
    }
    
    
    func create(req: Request) throws -> EventLoopFuture<Action> {
        let action = try req.content.decode(Action.self)
        return action.save(on: req.db).map { action }
    }
    
    
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Action.find(req.parameters.get("actionID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}
