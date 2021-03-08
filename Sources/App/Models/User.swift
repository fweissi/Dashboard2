//
//  User.swift
//  
//
//  Created by Keith Weiss on 2/25/21.
//

import Crypto
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    @Children(for: \.$user)
    var cardImages: [CardImage]
    
    @Children(for: \.$user)
    var tokens: [UserToken]
    
    @Siblings(
        through: TeamUserPivot.self,
        from: \.$user,
        to: \.$team)
    var teams: [Team]
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, email: String, passwordHash: String = "") {
        var hashedPassword: String = passwordHash
        if username == "admin" && passwordHash.isEmpty {
            do {
                hashedPassword = try Bcrypt.hash(Environment.get("ADMIN_PASSWORD")!)
            }
            catch {
                fatalError("Cannot create default admin user.")
            }
        }
        
        self.name = name
        self.username = username
        self.email = email
        self.passwordHash = hashedPassword
    }
    
    
    static var adminUser = User(name: "Administrator", username: "admin", email: "admin@brandwise.com")
}


//  Displaying Users but hiding sensative information
extension User {
    struct Public: Content {
        let id: UUID?
        let name: String
        let username: String
    }
    
    func toPublic() -> User.Public {
        Public(id: id, name: name, username: username)
    }
}



//  Extending for ModelAuthenticatable UserToken creation
extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}


extension User {
    struct Create: Content {
        var name: String
        var username: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}


extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("username", as: String.self, is: !.empty && .count(3...) && .alphanumeric)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}


extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username    // Can be switched to \User.$email if we want to use email as username
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}


extension User: ModelSessionAuthenticatable {}


struct UserModelCredentialsAuthenticator: CredentialsAuthenticator {
    
    struct Input: Content {
        let username: String
        let password: String
    }
    
    typealias Credentials = Input
    
    func authenticate(credentials: Credentials,
                      for req: Request) -> EventLoopFuture<Void> {
        User.query(on: req.db)
            .filter(\.$username == credentials.username)
            .first()
            .map {
                do {
                    if let user = $0,
                       try Bcrypt.verify(credentials.password, created: user.passwordHash) {
                        req.auth.login(user)
                    }
                }
                catch {
                    // do nothing...
                }
            }
    }
}
