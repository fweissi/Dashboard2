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
    if let awsS3BucketName = Environment.get("S3_BUCKET_NAME") {
        let s3Bucket = S3.Bucket(stringLiteral: awsS3BucketName)
        app.fileStorages.use(.awsS3(region: .uswest1, bucket: s3Bucket), as: .awsS3)
    }
    
    app.views.use(.leaf)
    
    if let databaseURL = Environment.get("DATABASE_URL"),
       var postgresConfig = PostgresConfiguration(url: databaseURL) {
        if Environment.Postgres.isProduction {
            postgresConfig.tlsConfiguration = .forClient(certificateVerification: .none)
        }
        
        app.databases.use(.postgres(
            configuration: postgresConfig
        ), as: .psql)
        
        app.databases.middleware.use(UserMiddleware(), on: .psql)
        
        app.migrations.add(CreateCard())
        app.migrations.add(CreateAction())
        app.migrations.add(CreateTodo())
        app.migrations.add(CreateCardImage())
        app.migrations.add(CreateUser())
        do {
            try app.autoMigrate().wait()
        }
        catch {
            app.logger.warning("Failed to Auto-Migrate: \(error)")
        }
        
    } else {
        app.logger.critical("Failed to open a database.")
    }
    
    // register routes
    try routes(app)
}
