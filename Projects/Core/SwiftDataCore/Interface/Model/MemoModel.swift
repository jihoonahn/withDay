import Foundation
import SwiftData

@Model
public final class MemosModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var title: String
    public var content: String
    public var blocksData: Data?
    @Transient public var blocks: [MemoBlockModel] {
        get {
            guard let blocksData = blocksData else { return [] }
            guard let decoded = try? JSONDecoder().decode([MemoBlockModel].self, from: blocksData) else {
                return []
            }
            return decoded
        }
        set {
            blocksData = try? JSONEncoder().encode(newValue)
        }
    }

    public var alarmId: UUID?
    public var scheduleId: UUID?
    public var reminderTime: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID,
        userId: UUID,
        title: String,
        content: String,
        blocks: [MemoBlockModel],
        alarmId: UUID? = nil,
        scheduleId: UUID? = nil,
        reminderTime: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        // blocksData를 직접 설정 (blocks setter를 통해 설정하면 SwiftData 매크로가 감지함)
        self.blocksData = try? JSONEncoder().encode(blocks)
        self.reminderTime = reminderTime
        self.alarmId = alarmId
        self.scheduleId = scheduleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct MemoBlockModel: Codable {
    public enum BlockType: String, Codable {
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
