import Foundation
import SchedulesDomainInterface

// MARK: - DTO
struct SchedulesDTO: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String
    let date: String
    let startTime: String
    let endTime: String
    let createdAt: Date
    let updatedAt: Date
    
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
    
    init(from entity: SchedulesEntity) {
        self.id = entity.id
        self.userId = entity.userId
        self.title = entity.title
        self.description = entity.description
        self.date = entity.date
        self.startTime = entity.startTime
        self.endTime = entity.endTime
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    func toEntity() -> SchedulesEntity {
        SchedulesEntity(
            id: id,
            userId: userId,
            title: title,
            description: description,
            date: date,
            startTime: startTime,
            endTime: endTime,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
