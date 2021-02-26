import Fluent
import Vapor

// String representable, Codable enum for animal types.
enum ActionType: String, Codable {
    case access360
    case accessReports
    case staticImage
    case directVideo
    case embeddedVideo
    case linkToWebsite
    case embeddedHTML
}


enum WebDisplayOption: String, Codable {
    case custom
    case application
    case external
}


enum ReponseOption: String, Codable {
    case information
    case noAccess
    case fullAccess
    case trial
}


final class Action: Model, Content {
    static let schema = "action"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "card_id")
    var card: Card
    
    @Enum(key: "type")
    var type: ActionType
    
    @Enum(key: "displayOption")
    var displayOption: WebDisplayOption
    
    @OptionalField(key: "displayWidth")
    var displayWidth: Int?
    
    @OptionalField(key: "displayHeight")
    var displayHeight: Int?
    
    @Enum(key: "responseOption")
    var responseOption: ReponseOption
    
    @OptionalField(key: "assetID")
    var assetID: String?
    
    @OptionalField(key: "urlPath")
    var urlPath: String?
    
    @OptionalField(key: "embeddedHTML")
    var embeddedHTML: String?
    
    @OptionalField(key: "start")
    var start: Date?
    
    @OptionalField(key: "end")
    var end: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        type: ActionType = .linkToWebsite,
        displayOption: WebDisplayOption = .application,
        responseOption: ReponseOption = .information,
        assetID: String?,
        urlPath: String?,
        embeddedHTML: String?,
        displayWidth: Int? = 640,
        displayHeight: Int? = 480,
        start: Date? = Date.distantPast,
        end: Date? = Date.distantFuture
    ) {
        self.id = id
        self.type = type
        self.displayOption = displayOption
        self.responseOption = responseOption
        self.assetID = assetID
        self.urlPath = urlPath
        self.embeddedHTML = embeddedHTML
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.start = start
        self.end = end
    }
}
