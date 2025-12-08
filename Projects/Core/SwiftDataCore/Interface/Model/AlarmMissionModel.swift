import Foundation
import SwiftData

@Model
public final class AlarmMissionsModel {
    @Attribute(.unique) public var id: UUID
    public var alarmId: UUID
    public var missionType: String
    public var difficulty: Int
    public var configData: Data? // MissionConfig를 JSON으로 저장
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID,
        alarmId: UUID,
        missionType: String,
        difficulty: Int,
        configData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.alarmId = alarmId
        self.missionType = missionType
        self.difficulty = difficulty
        self.configData = configData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

