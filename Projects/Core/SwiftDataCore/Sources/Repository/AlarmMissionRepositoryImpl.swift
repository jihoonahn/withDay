import Foundation
import AlarmMissionsDomainInterface
import SwiftDataCoreInterface

public final class AlarmMissionRepositoryImpl: AlarmMissionsRepository {

    private let alarmMissionService: SwiftDataCoreInterface.AlarmMissionsService

    public init(alarmMissionService: SwiftDataCoreInterface.AlarmMissionsService) {
        self.alarmMissionService = alarmMissionService
    }

    public func getMissions(alarmId: UUID) async throws -> [AlarmMissionsEntity] {
        let models = try await alarmMissionService.fetchMissions(alarmId: alarmId)
        return models.map { AlarmMissionsDTO.toEntity(from: $0) }
    }

    public func createMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity {
        let model = AlarmMissionsDTO.toModel(from: mission)
        try await alarmMissionService.saveMission(model)
        return mission
    }

    public func updateMission(_ mission: AlarmMissionsEntity) async throws {
        let model = AlarmMissionsDTO.toModel(from: mission)
        try await alarmMissionService.updateMission(model)
    }

    public func deleteMission(id: UUID) async throws {
        try await alarmMissionService.deleteMission(id: id)
    }
}
