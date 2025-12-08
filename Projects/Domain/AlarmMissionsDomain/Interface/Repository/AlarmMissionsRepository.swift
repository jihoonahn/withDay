import Foundation

public protocol AlarmMissionsRepository: Sendable {
    func getMissions(alarmId: UUID) async throws -> [AlarmMissionsEntity]
    func createMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity
    func updateMission(_ mission: AlarmMissionsEntity) async throws
    func deleteMission(id: UUID) async throws
}
