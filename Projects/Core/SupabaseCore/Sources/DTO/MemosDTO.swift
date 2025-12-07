import Foundation
import MemosDomainInterface

// MARK: - DTO
struct MemosDTO: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String
    let blocks: [MemoBlockDTO]
    let alarmId: UUID?
    let reminderTime: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case blocks
        case alarmId = "alarm_id"
        case reminderTime = "reminder_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from entity: MemosEntity) {
        self.id = entity.id
        self.userId = entity.userId
        self.title = entity.title
        self.description = entity.description
        self.blocks = entity.blocks.map { MemoBlockDTO(from: $0) }
        self.alarmId = entity.alarmId
        self.reminderTime = entity.reminderTime
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    func toEntity() -> MemosEntity {
        MemosEntity(
            id: id,
            userId: userId,
            title: title,
            description: description,
            blocks: blocks.map { $0.toEntity() },
            alarmId: alarmId,
            reminderTime: reminderTime,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct MemoBlockDTO: Codable {
    let id: UUID
    let type: String
    let content: String
    let children: [MemoBlockDTO]
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case content
        case children
    }
    
    init(from entity: MemoBlockEntity) {
        self.id = entity.id
        self.type = entity.type.rawValue
        self.content = entity.content
        self.children = entity.children.map { MemoBlockDTO(from: $0) }
    }
    
    func toEntity() -> MemoBlockEntity {
        MemoBlockEntity(
            id: id,
            type: MemoBlockEntity.BlockType(rawValue: type) ?? .text,
            content: content,
            children: children.map { $0.toEntity() }
        )
    }
}
