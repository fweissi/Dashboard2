/**
 * FILE:
 * Sources/App/Extensions/Environment+App.swift
 */
import Vapor

extension Environment {
    //...
    struct Postgres {
        /// postgres://myuser:mypass@localhost:5432/mydb
        static let databaseURL: String = Environment.get("DATABASE_URL") ?? ""
        static let hostname: String = Environment.get("HOST") ?? ""
        static let port: Int = Int(Environment.get("PORT") ?? "5432") ?? 5432
        static let username: String = Environment.get("USER_NAME") ?? ""
        static let password: String = Environment.get("PASSWORD") ?? ""
        static let database: String = Environment.get("DATABASE") ?? ""
    }
}
