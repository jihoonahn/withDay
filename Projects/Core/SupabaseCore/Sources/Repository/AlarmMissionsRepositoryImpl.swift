import Foundation
import Supabase
import AlarmMissionsDomainInterface
import SupabaseCoreInterface

// MARK: - Repository Implementation
public final class AlarmMissionsRepositoryImpl: AlarmMissionsRepository {
    private let alarmMissionsService: AlarmMissionsService
    
    public init(alarmMissionsService: AlarmMissionsService) {
        self.alarmMissionsService = alarmMissionsService
    }
    
    public func getMissions(alarmId: UUID) async throws -> [AlarmMissionsEntity] {
        return try await alarmMissionsService.getMissions(alarmId: alarmId)
    }

    public func createMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity {
        return try await alarmMissionsService.createMission(mission)
    }
    
    public func updateMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity {
        return try await alarmMissionsService.updateMission(mission)
    }
    
    public func deleteMission(id: UUID) async throws {
        return try await alarmMissionsService.deleteMission(id: id)
    }
}
