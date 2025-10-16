import Foundation
import Rex

public struct SettingState: StateType {
    public var user: User?
    public var isDarkMode: Bool = false
    public var isLoading: Bool = false
    public var error: String?
    
    public init() {}
}

public struct User: Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let email: String
    public let profileImageURL: String?
    
    public init(id: String, name: String, email: String, profileImageURL: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
    }
}
