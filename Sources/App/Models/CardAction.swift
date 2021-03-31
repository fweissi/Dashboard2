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
    
    @OptionalField(key: "baseOrResourceURL")
    var baseOrResourceURL: String?
    
    @OptionalField(key: "embeddedHTML")
    var embeddedHTML: String?
    
    @Field(key: "safari")
    var safariOption: SafariOption
    
    @Field(key: "size")
    var size: Size
    
    @Field(key: "version")
    var version: Int
    
    @Parent(key: "card_item_id")
    var cardItem: CardItem
    
    init() {}
    
    init(
        id: UUID? = nil,
        linkType: LinkType,
        baseOrResourceURL: String?,
        embeddedHTML: String?,
        safariOption: SafariOption = .modal,
        size: Size = Size.zero,
        version: Int = 0,
        cardItemID: CardItem.IDValue
    ) {
        self.id = id
        self.linkType = linkType
        self.baseOrResourceURL = baseOrResourceURL
        self.embeddedHTML = embeddedHTML
        self.safariOption = safariOption
        self.size = size
        self.version = version
        self.$cardItem.id = cardItemID
    }
    
    
    init(from actionLink: ActionLink, with cardItemID: CardItem.IDValue) {
        self.id = nil
        self.linkType = actionLink.linkType
        self.baseOrResourceURL = actionLink.baseOrResourceURL
        self.embeddedHTML = actionLink.embeddedHTML
        self.safariOption = actionLink.safariOption ?? .modal
        self.size = actionLink.size
        self.version = actionLink.version
        self.$cardItem.id = cardItemID
    }
}
