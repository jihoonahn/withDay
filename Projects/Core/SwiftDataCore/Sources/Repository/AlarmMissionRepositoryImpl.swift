import Foundation
import AlarmMissionsDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class AlarmMissionRepositoryImpl: AlarmMissionsRepository {
    private let alarmMissionService: SwiftDataCoreInterface.AlarmMissionService
    
    public init(alarmMissionService: SwiftDataCoreInterface.AlarmMissionService) {
        self.alarmMissionService = alarmMissionService
    }
    
    public func getMissions(alarmId: UUID) async throws -> [AlarmMissionsEntity] {
        let models = try await alarmMissionService.fetchMissions(alarmId: alarmId)
        return models.map { AlarmMissionDTO.toEntity(from: $0) }
    }
    
    public func createMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity {
        let model = AlarmMissionDTO.toModel(from: mission)
        try await alarmMissionService.saveMission(model)
        return mission
    }
    
    public func updateMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity {
        let model = AlarmMissionDTO.toModel(from: mission)
        try await alarmMissionService.updateMission(model)
        return mission
    }
    
    public func deleteMission(id: UUID) async throws {
        try await alarmMissionService.deleteMission(id: id)
    }
}

