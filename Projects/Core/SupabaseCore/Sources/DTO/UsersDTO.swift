import Foundation
import UsersDomainInterface

struct UsersDTO: Codable {
    let id: UUID
    let provider: String
    let email: String?
    let displayName: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case provider
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from entity: UsersEntity) {
        self.id = entity.id
        self.provider = entity.provider
        self.email = entity.email
        self.displayName = entity.displayName
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    func toEntity() -> UsersEntity {
        UsersEntity(
            id: id,
            provider: provider,
            email: email,
            displayName: displayName,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
