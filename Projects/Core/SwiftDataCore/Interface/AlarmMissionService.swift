import Foundation

public protocol AlarmMissionsService: Sendable {
    func fetchMissions(alarmId: UUID) async throws -> [AlarmMissionsModel]
    func saveMission(_ mission: AlarmMissionsModel) async throws
    func updateMission(_ mission: AlarmMissionsModel) async throws
    func deleteMission(id: UUID) async throws
}
