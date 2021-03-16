import Fluent
import Vapor

final class Card: Model, Content {
    static let schema = "cards"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "isBanner")
    var isBanner: Bool
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "details")
    var details: String
    
    @OptionalField(key: "assetID")
    var assetID: String?
    
    @OptionalField(key: "assetPath")
    var assetPath: String?
    
    @OptionalField(key: "start")
    var start: Date?
    
    @OptionalField(key: "end")
    var end: Date?
    
    @Children(for: \.$card)
    var actions: [Action]
    
    init() { }
    
    init(
        id: UUID? = nil,
        isBanner: Bool = false,
        title: String,
        details: String,
        assetID: String?,
        assetPath: String?,
        start: Date? = Date.distantPast,
        end: Date? = Date.distantFuture
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.assetID = assetID
        self.assetPath = assetPath
        self.details = details
        self.start = start
        self.end = end
    }
}
