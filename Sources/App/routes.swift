import Leaf
import Vapor
import Liquid
import LiquidAwsS3Driver

func routes(_ app: Application) throws {
    app.get() { req -> EventLoopFuture<View> in
        return req.view.render("index")
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    app.post("upload") { (req) -> EventLoopFuture<String> in
        var key = try req.query.get(String.self, at: "key")
        if key == "test.jpg" {
            key = UUID().uuidString + ".jpg"
        }
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .flatMap { req.fs.upload(key: key, data: Data(buffer: $0)) }
        // returns the full public url of the uploaded image
    }

    try app.register(collection: TodoController())
}

