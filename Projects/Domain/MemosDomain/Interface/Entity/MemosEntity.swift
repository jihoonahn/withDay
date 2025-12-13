import Foundation

public struct MemosEntity: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let description: String
    public let blocks: [MemoBlockEntity]
    public let alarmId: UUID?
    public let scheduleId: UUID?
    public let reminderTime: String?
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case blocks
        case alarmId = "alarm_id"
        case scheduleId = "schedule_id"
        case reminderTime = "reminder_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID,
        userId: UUID,
        title: String,
        description: String,
        blocks: [MemoBlockEntity],
        alarmId: UUID? = nil,
        scheduleId: UUID? = nil,
        reminderTime: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.blocks = blocks
        self.alarmId = alarmId
        self.scheduleId = scheduleId
        self.reminderTime = reminderTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct MemoBlockEntity: Equatable, Sendable, Codable {
    public enum BlockType: String, Sendable, Codable {
        case text
        case heading
        case checklist
        case image
        case divider
    }

    public let id: UUID
    public var type: BlockType
    public var content: String
    public var children: [MemoBlockEntity]

    public init(
        id: UUID = UUID(),
        type: BlockType,
        content: String,
        children: [MemoBlockEntity] = []
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.children = children
    }
}
