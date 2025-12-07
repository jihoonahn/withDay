import Foundation
import AlarmMissionsDomainInterface

// MARK: - DTO
struct AlarmMissionsDTO: Codable {
    let id: UUID
    let alarmId: UUID
    let missionType: String
    let difficulty: Int
    let config: MissionConfig?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case alarmId = "alarm_id"
        case missionType = "mission_type"
        case difficulty
        case config
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from entity: AlarmMissionsEntity) {
        self.id = entity.id
        self.alarmId = entity.alarmId
        self.missionType = entity.missionType
        self.difficulty = entity.difficulty
        self.config = entity.config
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    func toEntity() -> AlarmMissionsEntity {
        AlarmMissionsEntity(
            id: id,
            alarmId: alarmId,
            missionType: missionType,
            difficulty: difficulty,
            config: config,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

