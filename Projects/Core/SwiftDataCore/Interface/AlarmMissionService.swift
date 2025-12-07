import Foundation

public protocol AlarmMissionService: Sendable {
    func fetchMissions(alarmId: UUID) async throws -> [AlarmMissionModel]
    func saveMission(_ mission: AlarmMissionModel) async throws
    func updateMission(_ mission: AlarmMissionModel) async throws
    func deleteMission(id: UUID) async throws
}

