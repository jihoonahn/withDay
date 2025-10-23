import Foundation
import MemoDomainInterface

struct MemoDTO: Codable {
    let id: UUID
    let userId: UUID
    let content: String
    let date: Date
    let alarmId: UUID?
    let reminderTime: String? // "HH:mm"
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case date
        case alarmId = "alarm_id"
        case reminderTime = "reminder_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from entity: MemoEntity) {
        self.id = entity.id
        self.userId = entity.userId
        self.content = entity.content
        self.date = entity.date
        self.alarmId = entity.alarmId
        self.reminderTime = entity.reminderTime
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    func toEntity() -> MemoEntity {
        MemoEntity(
            id: id,
            userId: userId,
            content: content,
            date: date,
            alarmId: alarmId,
            reminderTime: reminderTime,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
