import Foundation
import AlarmMissionsDomainInterface

public final class AlarmMissionUseCaseImpl: AlarmMissionsUseCase {
    private let alarmMissionsRepository: AlarmMissionsRepository
    
    public init(alarmMissionsRepository: AlarmMissionsRepository) {
        self.alarmMissionsRepository = alarmMissionsRepository
    }
    
    public func fetchMissions(alarmId: UUID) async throws -> [AlarmMissionsEntity] {
        return try await alarmMissionsRepository.getMissions(alarmId: alarmId)
    }
    
    public func createMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity {
        return try await alarmMissionsRepository.createMission(mission)
    }
    
    public func updateMission(_ mission: AlarmMissionsEntity) async throws {
        return try await alarmMissionsRepository.updateMission(mission)
    }
    
    public func deleteMission(id: UUID) async throws {
        try await alarmMissionsRepository.deleteMission(id: id)
    }
}

