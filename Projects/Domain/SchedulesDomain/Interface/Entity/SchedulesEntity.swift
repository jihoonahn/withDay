import Foundation

public struct SchedulesEntity: Identifiable, Hashable, Codable, Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let description: String
    public let date: String
    public let startTime: String
    public let endTime: String
    public let createdAt: Date
    public let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case date
        case startTime = "start_time"
        case endTime = "end_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(
        id: UUID,
        userId: UUID,
        title: String,
        description: String,
        date: String,
        startTime: String,
        endTime: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
