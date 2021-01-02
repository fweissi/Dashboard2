import Fluent
import FluentSQLiteDriver
import Leaf
import Liquid
import LiquidLocalDriver
import Vapor

let imageDirectory: String = "images"
// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.routes.defaultMaxBodySize = "10mb"
    
    // using the local driver
    app.fileStorages.use(.local(publicUrl: "http://localhost:8080/",
                                publicPath: app.directory.publicDirectory,
                                workDirectory: imageDirectory), as: .local)
    
    app.views.use(.leaf)

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    app.migrations.add(CreateTodo())
    
    app.post("upload") { (req) -> EventLoopFuture<String> in
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
    
    app.post("upload","image") { (req) -> EventLoopFuture<String> in
        let key = try req.query.get(String.self, at: "key")
        let path = req.application.directory.publicDirectory + imageDirectory + "/" + key
        
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .flatMap { req.fileio.writeFile($0, at: path) }
            .map { key }
    }
    
    app.post("upload","test") { (req) -> EventLoopFuture<String> in
        let key = try req.query.get(String.self, at: "key")
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .flatMap { req.fs.upload(key: key, data: Data(buffer: $0)) }
        // returns the full public url of the uploaded image
    }

    // register routes
    try routes(app)
}
