import Fluent
import Vapor

struct ActionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let actions = routes.grouped("actions")
        actions.get(use: getAllHandler)
        actions.post(use: createHandler)
        
        actions.group(":actionID") { action in
            action.delete(use: deleteHandler)
        }
    }
    
    
    func getAllHandler(req: Request) throws -> EventLoopFuture<[Action]> {
        Action.query(on: req.db).all()
    }
    
    
    func createHandler(req: Request) throws -> EventLoopFuture<Action> {
        let action = try req.content.decode(Action.self)
        return action.save(on: req.db).map { action }
    }
    
    
    func deleteHandler(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        Action.find(req.parameters.get("actionID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}
