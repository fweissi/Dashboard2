import Leaf
import Vapor

func routes(_ app: Application) throws {
    app.get() { req -> EventLoopFuture<View> in
        return req.view.render("index")
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    app.post("upload","image") { (req) -> EventLoopFuture<String> in
        let formData = try req.content.decode(FormData.self)
//        let key = try req.query.get(String.self, at: "key")
        struct FormData: Content {
            let key: String
            let file: Data
        }
        let path = req.application.directory.publicDirectory + imageDirectory + "/" + formData.key
        
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .flatMap { _ in req.fileio.writeFile(ByteBuffer(data: formData.file), at: path) }
            .map { path }
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
}
