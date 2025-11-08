import Foundation

public struct LocalizationEntity: Equatable, Codable {
    public var languageCode: String
    public var updatedAt: Date
    
    public init(languageCode: String, updatedAt: Date = Date()) {
        self.languageCode = languageCode
        self.updatedAt = updatedAt
    }
}
