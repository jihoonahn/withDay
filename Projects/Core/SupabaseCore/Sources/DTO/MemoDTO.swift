import Foundation
import MemoDomainInterface

struct MemoDTO: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let content: String
    let alarmId: UUID?
    let reminderTime: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case alarmId = "alarm_id"
        case reminderTime = "reminder_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from entity: MemoEntity) {
        self.id = entity.id
        self.userId = entity.userId
        self.title = entity.title
        self.content = entity.content
        self.alarmId = entity.alarmId
        self.reminderTime = entity.reminderTime
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    func toEntity() -> MemoEntity {
        MemoEntity(
            id: id,
            userId: userId,
            title: title,
            content: content,
            alarmId: alarmId,
            reminderTime: reminderTime,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
