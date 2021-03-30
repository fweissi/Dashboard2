//
//  CardAction.swift
//  
//
//  Created by Keith Weiss on 3/30/21.
//

import Fluent
import Vapor

final class CardAction: Model, Content {
    static let schema = "card_actions"
    
    @ID
    var id: UUID?
    
    @Field(key: "linkType")
    var linkType: LinkType
    
    @Field(key: "baseOrResourceURL")
    var baseOrResourceURL: String
    
    @Field(key: "safariOption")
    var safariOption: SafariOption
    
    @Field(key: "size")
    var size: Size
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "card_item_id")
    var cardItem: CardItem
    
    init() {}
    
    
}
