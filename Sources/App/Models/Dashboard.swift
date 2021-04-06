//
//  Dashboard.swift
//  Dashboard Maker
//
//  Created by Keith Weiss on 3/14/21.
//

import Foundation

class Dashboard: Codable {
    var items: [Item]
    
    init(
        items: [Item]
    ) {
        self.items = items
    }
    
    
    func card(for cardImage: CardImage) -> Item? {
        let imageURI = cardImage.uri
        
        for item in items {
            if let _ = item.links.first(where: { $0.baseOrResourceURL == imageURI }) {
                return item
            }
        }
 
        return nil
    }
    
    func uses(cardImage: CardImage) -> Bool {
        let imageURL = cardImage.uri
        let links: [ActionLink] = items.extractLinks()
        return links.first(where: { $0.baseOrResourceURL == imageURL }) != nil
    }
    
    static var empty: Dashboard = Dashboard(items: [Item]())
}


// Array Extension
extension Array where Element == Item {
    func extractLinks() -> [ActionLink] {
        self.compactMap { $0.asset() }
    }
}


enum Category: String, Codable, CaseIterable {
    case inAppPurchase = "InAppPurchase"
    case video = "Video"
    case promotion = "Promo"
    case information = "Info"
}

enum PurchaseRequirement: String, Codable, CaseIterable {
    case none = ""
    case vision360 = "Vision360"
    case vision = "Vision"
    
    var deepLink: String {
        switch self {
        case .vision360:
            return "brandwise://openVision360"
        case .vision:
            return "brandwise://openVision"
        default:
            return ""
        }
    }
    
    var title: String {
        switch self {
        case .vision360, .vision:
            return self.rawValue
        default:
            return "None"
        }
    }
}

enum CardSize: String, CaseIterable {
    case hero = "Hero"
    case regular = "Regular"
    
    var rect: CGSize {
        switch self {
        case .hero:
            return CGSize(width: 620, height: 400)
        default:
            return CGSize(width: 300, height: 300)
        }
    }
    
    static func cardSize(for assetSize: Size) -> CardSize {
        if assetSize.width == 620 {
            return .hero
        }
        else {
            return .regular
        }
    }
}

class Item: Codable {
    
    var id: UUID?
    var isInternetRequired: Bool
    var isPinned: Bool
    var purchaseRequirement: PurchaseRequirement
    var category: Category
    var title: String
    var callToAction: String
    var links: [ActionLink]
    
    var isInAppPurchase: Bool {
        category == .inAppPurchase
    }
    
    var cardSize: CardSize {
        guard let asset = asset() else { return .regular }
        
        return CardSize.cardSize(for: asset.size)
    }
    
    init(
        id: UUID?,
        isInternetRequired: Bool,
        isPinned: Bool,
        purchaseRequirement: PurchaseRequirement,
        category: Category,
        title: String,
        callToAction: String,
        links: [ActionLink]
    ) {
        self.isInternetRequired = isInternetRequired
        self.isPinned = isPinned
        self.purchaseRequirement = purchaseRequirement
        self.category = category
        self.title = title
        self.callToAction = callToAction
        self.links = links
    }
    
    
    func asset() -> ActionLink? {
        self.actionLink(for: .asset)
    }
    
    
    func actionLink(for linkType: LinkType) -> ActionLink? {
         self.links.first(where: { $0.linkType == linkType })
    }
    
    
    func baseURL(for linkType: LinkType) -> String? {
        self.actionLink(for: linkType)?.baseOrResourceURL
    }
}



enum LinkType: String, CaseIterable, Codable {
    case asset
    case primary
    case secondary
    case tertiary
}

enum SafariOption: String, CaseIterable, Codable {
    case modal      =   "Modal"
    case safari     =   "Safari"
    case webView    =   "WebView"
}

enum CustomSize: String, CaseIterable, Codable {
    case standard
    case video
    case other
    
    var size: Size {
        switch self {
        case .video:
            return Size(width: 560, height: 320)
        case .standard:
            return Size(width: 720, height: 600)
        default:
            return Size(width: 0, height: 0)
        }
    }
    
    var title: String {
        switch self {
        case .video:
            return "Video (560 x 320)"
        case .standard:
            return "Standard (720, 600)"
        default:
            return "Other"
        }
    }
    
    init(size: Size) {
        if size == CustomSize.video.size {
            self.init(rawValue: CustomSize.video.rawValue)!
        }
        else if size == CustomSize.standard.size {
            self.init(rawValue: CustomSize.standard.rawValue)!
        }
        else {
            self.init(rawValue: CustomSize.other.rawValue)!
        }
    }
}

struct Size: Codable, Equatable {
    var width: Int
    var height: Int
    
    init(
        width: Int,
        height: Int
    ) {
        self.width = width
        self.height = height
    }
    
    init(cgSize: CGSize) {
        self.width = Int(cgSize.width)
        self.height = Int(cgSize.height)
    }
    
    
    static func ==(lhs: Size, rhs: Size) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height
    }
    
    static var zero = Size(width: 0, height: 0)
}


class ActionLink: Codable {
    
    var id: UUID?
    var linkType: LinkType
    var baseOrResourceURL: String?
    var embeddedHTML: String?
    var safariOption: SafariOption?
    var size: Size
    var version: Int
    
    init(
        id: UUID?,
        linkType: LinkType,
        baseOrResourceURL: String?,
        embeddedHTML: String?,
        safariOption: SafariOption?,
        size: Size,
        version: Int
    ) {
        self.linkType = linkType
        self.baseOrResourceURL = baseOrResourceURL
        self.embeddedHTML = embeddedHTML
        self.safariOption = safariOption ?? SafariOption.modal
        self.size = size
        self.version = version
    }
}




