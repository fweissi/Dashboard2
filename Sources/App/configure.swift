import Fluent
import FluentPostgresDriver
import Leaf
import Liquid
import LiquidAwsS3Driver
import Vapor

let imageDirectory: String = "images"
// configures your application
public func configure(_ app: Application) throws {
    app.sessions.use(.fluent)
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(UserModelCredentialsAuthenticator())
//    app.middleware.use(User.redirectMiddleware(path: "/login"))
    // Change the cookie name to "foo".
    app.sessions.configuration.cookieName = "dashboard2"

    // Configures cookie value creation.
    app.sessions.configuration.cookieFactory = { sessionID in
        .init(string: sessionID.string, isSecure: true)
    }
    
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.routes.defaultMaxBodySize = "10mb"
    
    // using the local driver
    if let awsS3BucketName = Environment.get("S3_BUCKET_NAME") {
        let s3Bucket = S3.Bucket(stringLiteral: awsS3BucketName)
        app.fileStorages.use(.awsS3(region: .uswest1, bucket: s3Bucket), as: .awsS3)
    }
    
    if var postgresConfig = PostgresConfiguration(url: Environment.Postgres.databaseURL) {
        if Environment.Postgres.isProduction {
            postgresConfig.tlsConfiguration = .forClient(certificateVerification: .none)
        }
        
        app.databases.use(.postgres(
            configuration: postgresConfig
        ), as: .psql)
        
        app.databases.middleware.use(UserMiddleware(), on: .psql)
        
        app.migrations.add(CreateTeam())
        app.migrations.add(CreateUser())
        app.migrations.add(CreateTeamUserPivot())
        app.migrations.add(CreateUserToken())
        app.migrations.add(CreateCardImage())
        app.migrations.add(CreateTodo())
        app.migrations.add(CreateCardItem())
        app.migrations.add(CreateCardAction())
        app.migrations.add(SessionRecord.migration)
        
        app.migrations.add(TeamMigrationSeed())
        app.migrations.add(UserMigrationSeed())
        app.migrations.add(TeamUserPivotMigrationSeed())
        
        do {
            try app.autoMigrate().wait()
        }
        catch {
            app.logger.warning("Failed to Auto-Migrate: \(error)")
        }
        
    }
    else {
        app.logger.critical("Failed to open a database.")
    }
    
    
    app.views.use(.leaf)
    
    // register routes
    try routes(app)
}
