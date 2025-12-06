import Foundation

public protocol AlarmMissionsRepository {
    func getMissions(alarmId: UUID) async throws -> [AlarmMissionsEntity]
    func getMission(id: UUID) async throws -> AlarmMissionsEntity?
    func createMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity
    func updateMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity
    func deleteMission(id: UUID) async throws
}
