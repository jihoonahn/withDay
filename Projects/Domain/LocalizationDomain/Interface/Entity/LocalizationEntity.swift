import Foundation

public struct LocalizationEntity: Equatable, Codable, Identifiable {
    public var languageCode: String
    public var languageLabel: String
    public var updatedAt: Date
    
    public var id: String { languageCode }
    
    public init(languageCode: String, languageLabel: String, updatedAt: Date = Date()) {
        self.languageCode = languageCode
        self.languageLabel = languageLabel
        self.updatedAt = updatedAt
    }
}
