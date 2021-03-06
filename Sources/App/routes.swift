import Leaf
import Vapor
import Liquid
import LiquidAwsS3Driver

func routes(_ app: Application) throws {
    app.get("login") { req -> EventLoopFuture<View> in
        req.view.render("login", ["title" : "Login", "error" : "login"])
    }
    app.post("login") { req -> Response in
        guard let user = req.auth.get(User.self) else {
            return req.redirect(to: "/login?error")
        }
        req.session.authenticate(user)
        return req.redirect(to: "/")
    }
    
    app.get() { req -> EventLoopFuture<View> in
        guard req.hasSession
        else {
            return req
                .view
                .render("login", ["title" : "Login", "error" : "login"])
        }
        
        return req.view.render("index")
    }
    
    app.get("logout") { req -> Response in
        req.auth.logout(User.self)
        req.session.destroy()
        return req.redirect(to: "/")
    }
    
    app.post("upload") { (req) -> EventLoopFuture<String> in
        let key = try req.query.get(String.self, at: "key").replacingOccurrences(of: " ", with: "_")
        guard let uuidString = req.session.data["_UserSession"] else { throw Abort(.unauthorized) }
        
        return User.find(UUID(uuidString: uuidString), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user -> EventLoopFuture<String> in
                return req.body.collect()
                    .unwrap(or: Abort(.noContent))
                    .flatMap { data in
                        req.fs.upload(key: key, data: Data(buffer: data)).flatMap { uri in
                            guard let cardImage = try? CardImage(uri: uri, key: key, user: user)
                            else { fatalError() }
                            return cardImage.save(on: req.db).map { uri }
                        }
                    }
            }
    }
    
    try app.register(collection: ActionController())
    try app.register(collection: CardController())
    try app.register(collection: CardImageController())
    try app.register(collection: TeamController())
    try app.register(collection: TodoController())
    try app.register(collection: UserController())
}


struct LoginPostData: Content {
  let username: String
  let password: String
}

