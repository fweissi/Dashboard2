/**
 * FILE:
 * Sources/App/Extensions/Environment+App.swift
 */
import Vapor

extension Environment {
    //...
    struct Postgres {
        /// postgres://myuser:mypass@localhost:5432/mydb
        static let databaseURL = Environment.get("DATABASE_URL")!
//        static let host = Environment.get("HOST")!
//        static let username = Environment.get("USER_NAME")!
//        static let password = Environment.get("PASSWORD")!
//        static let database = Environment.get("DATABASE")!
    }
}
