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
    
    @Field(key: "type")
    var linkType: LinkType
    
    @Field(key: "baseOrResourceURL")
    var baseOrResourceURL: String
    
    @Field(key: "safari")
    var safariOption: SafariOption
    
    @Field(key: "size")
    var size: Size
    
    @Field(key: "version")
    var version: Int
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "card_item_id")
    var cardItem: CardItem
    
    init() {}
    
    init(
        id: UUID? = nil,
        linkType: LinkType = .asset,
        baseOrResourceURL: String = "",
        safariOption: SafariOption = .modal,
        size: Size = Size.zero,
        version: Int = 0,
        userID: User.IDValue,
        cardItemID: CardItem.IDValue
    ) {
        self.id = id
        self.linkType = linkType
        self.baseOrResourceURL = baseOrResourceURL
        self.safariOption = safariOption
        self.size = size
        self.version = version
        self.$user.id = userID
        self.$cardItem.id = cardItemID
    }
}
