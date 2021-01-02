import Fluent
import FluentSQLiteDriver
import Leaf
import Liquid
import LiquidAwsS3Driver
import Vapor

let imageDirectory: String = "images"
// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.routes.defaultMaxBodySize = "10mb"
    
    // using the local driver
    app.fileStorages.use(.awsS3(region: .uswest1, bucket: "playdashboard"), as: .awsS3)
    
    app.views.use(.leaf)

    // register routes
    try routes(app)
}
