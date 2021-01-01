import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.routes.defaultMaxBodySize = "10mb"

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    app.migrations.add(CreateTodo())
    
    app.post("upload") { (req) -> EventLoopFuture<String> in
        let formData = try req.content.decode(FormData.self)
//        let key = try req.query.get(String.self, at: "key")
        struct FormData: Content {
            let key: String
            let file: Data
        }
        let path = req.application.directory.publicDirectory + "Images/" + formData.key
        
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .flatMap { _ in req.fileio.writeFile(ByteBuffer(data: formData.file), at: path) }
            .map { path }
    }
    
    app.post("upload","image") { (req) -> EventLoopFuture<String> in
        let key = try req.query.get(String.self, at: "key")
        let path = req.application.directory.publicDirectory + "Images/" + key
        
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .flatMap { req.fileio.writeFile($0, at: path) }
            .map { key }
    }

    // register routes
    try routes(app)
}
