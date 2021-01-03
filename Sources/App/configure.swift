import Fluent
import FluentPostgresDriver
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
    
//    let postgresDatabase = DatabaseConfigurationFactory.postgres(
//        hostname: Environment.Postgres.hostname,
//        port: Environment.Postgres.port,
//        username: Environment.Postgres.username,
//        password: Environment.Postgres.password,
//        database: Environment.Postgres.database)
    
    if let postgresDatabase = try? DatabaseConfigurationFactory.postgres(url: Environment.Postgres.databaseURL) {
        
        app.databases.use(postgresDatabase, as: .psql)
        
        app.migrations.add(CreateTodo())
        do {
            try app.autoMigrate().wait()
        }
        catch {
            app.logger.critical("Failed to open a database.")
        }
    }
    else {
        app.logger.critical("Failed to open a database.")
    }
    
    // register routes
    try routes(app)
}
