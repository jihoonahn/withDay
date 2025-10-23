import Foundation

public struct MemoEntity: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let content: String
    public let date: Date
    public let alarmId: UUID?
    public let reminderTime: String? // "HH:mm"
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: UUID, userId: UUID, content: String, date: Date, alarmId: UUID? = nil, reminderTime: String? = nil, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.content = content
        self.date = date
        self.alarmId = alarmId
        self.reminderTime = reminderTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
