/**
 * FILE:
 * Sources/App/Extensions/Environment+App.swift
 */
import Vapor

extension Environment {
    //...
    struct Postgres {
        /// postgres://myuser:mypass@localhost:5432/mydb
        static let isProduction: Bool = Bool(Environment.get("IS_PRODUCTION") ?? "false") ?? false
        static let databaseURL: String = Environment.get("DATABASE_URL") ?? ""
    }
}
