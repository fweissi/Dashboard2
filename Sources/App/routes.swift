import Leaf
import Vapor
import Liquid
import LiquidAwsS3Driver

func routes(_ app: Application) throws {
    app.get() { req -> EventLoopFuture<View> in
        guard req.hasSession else { return req.view.render("login", ["title" : "Login", "error" : "login"])}
        return req.view.render("index")
    }
    app.get("login") { req -> EventLoopFuture<View> in
        guard !req.hasSession else { return req.view.render("index")}
        return req.view.render("login", ["title" : "Login", "error" : "error"])
    }
    app.post("login") { req -> Response in
        print("---> Session? \(req.hasSession ? "YES" : "no")")
        guard req.hasSession else { return req.redirect(to: "/login?error") }
        return req.redirect(to: "/")
    }
    app.get("logout") { req -> EventLoopFuture<View> in
        req.auth.logout(User.self)
        req.session.destroy()
        return req.view.render("index")
    }
    
    let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login"))
    protectedRoutes.post("upload") { (req) -> EventLoopFuture<String> in
        var key = try req.query.get(String.self, at: "key")
        if key == "test.jpg" {
            key = UUID().uuidString + ".jpg"
        }
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .flatMap { req.fs.upload(key: key, data: Data(buffer: $0)) }
        // returns the full public url of the uploaded image
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

