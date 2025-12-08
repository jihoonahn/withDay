import Foundation
import SwiftData

@Model
public final class MemosModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var title: String
    public var content: String
    public var blocks: [MemoBlockModel]
    public var alarmId: UUID
    public var reminderTime: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID,
        userId: UUID,
        title: String,
        content: String,
        blocks: [MemoBlockModel],
        alarmId: UUID,
        reminderTime: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.blocks = blocks
        self.reminderTime = reminderTime
        self.alarmId = alarmId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct MemoBlockModel {
    public enum BlockType {
        case text
        case heading
        case checklist
        case image
        case divider
    }

    public let id: UUID
    public var type: BlockType
    public var content: String
    public var children: [MemoBlockModel]

    public init(
        id: UUID = UUID(),
        type: BlockType,
        content: String,
        children: [MemoBlockModel] = []
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.children = children
    }
}
