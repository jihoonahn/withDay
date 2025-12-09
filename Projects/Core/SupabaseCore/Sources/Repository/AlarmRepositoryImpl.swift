import Foundation
import Supabase
import AlarmsDomainInterface
import SupabaseCoreInterface

// MARK: - Repository Implementation
public final class AlarmsRepositoryImpl: AlarmsRepository {

    private let alarmsService: AlarmsService
    
    public init(alarmsService: AlarmsService) {
        self.alarmsService = alarmsService
    }
    
    public func fetchAlarms(userId: UUID) async throws -> [AlarmsEntity] {
        try await alarmsService.getAlarms(userId: userId)
    }
    
    public func createAlarm(_ alarm: AlarmsEntity) async throws {
        try await alarmsService.createAlarm(alarm)
    }
    
    public func updateAlarm(_ alarm: AlarmsEntity) async throws {
        try await alarmsService.updateAlarm(alarm)
    }
    
    public func deleteAlarm(alarmId: UUID) async throws {
        try await alarmsService.deleteAlarm(alarmId)
    }
    
    public func toggleAlarm(alarmId: UUID, isEnabled: Bool) async throws {
        try await alarmsService.toggleAlarm(alarmId, isEnabled: isEnabled)
    }
}
