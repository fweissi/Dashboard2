//
//  User.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Crypto
import Fluent
import Vapor

final class User: Model, Content, Authenticatable {
    static let schema = "users"
    
    struct Public: Content {
        let id: UUID?
        let name: String
        let username: String
    }
    
    
    struct PasswordAuthenticator: BasicAuthenticator {
        typealias User = App.User
        
        func authenticate(
            basic: BasicAuthorization,
            for request: Request
        ) -> EventLoopFuture<Void> {
            User.query(on: request.db)
                .filter(\.$username == basic.username)
                .first()
                .flatMap { user in
                    if let user = user,
                       let verified = try? Bcrypt.verify(basic.password, created: user.password),
                       verified {
                        request.auth.login(user)
                    }
                    
                    return request.eventLoop.makeSucceededFuture(())
                }
        }
    }


    struct TokenAuthenticator: BearerAuthenticator {
        typealias User = App.User

        func authenticate(
            bearer: BearerAuthorization,
            for request: Request
        ) -> EventLoopFuture<Void> {
           if bearer.token == "foo" {
               request.auth.login(User.adminUser)
           }
           return request.eventLoop.makeSucceededFuture(())
       }
    }
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    @Timestamp(key: "deleted_at", on: .delete)
        var deletedAt: Date?
    
    @Children(for: \.$user)
    var cardImages: [CardImage]
    
    @Siblings(
        through: TeamUserPivot.self,
        from: \.$user,
        to: \.$team)
    var teams: [Team]
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, email: String, password: String) {
        var encryptedPassword: String = password
        if username == "admin" && password.isEmpty {
            do {
                encryptedPassword = try Bcrypt.hash(Environment.get("ADMIN_PASSWORD")!)
            }
            catch {
                fatalError("Cannot create default admin user.")
            }
        }
        
        self.name = name
        self.username = username
        self.email = email
        self.password = encryptedPassword
    }
    
    
    func toPublic() -> User.Public {
        Public(id: id, name: name, username: username)
    }
    
    
    static var adminUser = User(name: "Administrator", username: "admin", email: "admin@brandwise.com", password: "")
}


extension User: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
