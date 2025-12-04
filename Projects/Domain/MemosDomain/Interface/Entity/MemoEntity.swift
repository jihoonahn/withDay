import Foundation

public struct MemoEntity: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var title: String
    public var content: String
    public var alarmId: UUID?
    public var reminderTime: String?
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        id: UUID,
        userId: UUID,
        title: String,
        content: String,
        alarmId: UUID? = nil,
        reminderTime: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.alarmId = alarmId
        self.reminderTime = reminderTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
