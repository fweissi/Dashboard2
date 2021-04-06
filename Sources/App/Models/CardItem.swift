//
//  CardItem.swift
//  
//
//  Created by Keith Weiss on 3/30/21.
//

import Fluent
import Vapor

final class CardItem: Model, Content {
    static let schema = "card_items"
    
    @ID
    var id: UUID?
    
    @Field(key: "isInternetRequired")
    var isInternetRequired: Bool
    
    @Field(key: "isPinned")
    var isPinned: Bool
    
    @Field(key: "purchaseRequirement")
    var purchaseRequirement: PurchaseRequirement
    
    @Field(key: "category")
    var category: Category
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "callToAction")
    var callToAction: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Children(for: \.$cardItem)
    var links: [CardAction]
    
    init() {}
    
    init(
        id: UUID? = nil,
        isInternetRequired: Bool = false,
        isPinned: Bool = false,
        purchaseRequirement: PurchaseRequirement = .none,
        category: Category = .information,
        title: String = "",
        callToAction: String = "",
        userID: User.IDValue
    ) {
        self.id = id
        self.isInternetRequired = isInternetRequired
        self.isPinned = isPinned
        self.purchaseRequirement = purchaseRequirement
        self.category = category
        self.title = title
        self.callToAction = callToAction
        self.$user.id = userID
    }
    
    
    init(from cardItem: Item, with userID: User.IDValue) {
        self.id = cardItem.id ?? UUID()
        self.isInternetRequired = cardItem.isInternetRequired
        self.isPinned = cardItem.isPinned
        self.purchaseRequirement = cardItem.purchaseRequirement
        self.category = cardItem.category
        self.title = cardItem.title
        self.callToAction = cardItem.callToAction
        self.$user.id = userID
    }
    
    
    struct Dashboard: Content {
        let items: [CardItem]
    }
}
