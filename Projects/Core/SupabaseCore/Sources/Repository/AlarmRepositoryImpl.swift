import Foundation
import AlarmDomainInterface
import SupabaseCoreInterface

public final class AlarmRepositoryImpl: AlarmRepository {
    private let alarmDataService: SupabaseCoreInterface.AlarmService
    
    public init(alarmDataService: SupabaseCoreInterface.AlarmService) {
        self.alarmDataService = alarmDataService
    }
    
    public func fetchAlarms(userId: UUID) async throws -> [AlarmEntity] {
        return try await alarmDataService.fetchAlarms(for: userId)
    }
    
    public func createAlarm(_ alarm: AlarmEntity) async throws {
        try await alarmDataService.createAlarm(alarm)
    }
    
    public func updateAlarm(_ alarm: AlarmEntity) async throws {
        try await alarmDataService.updateAlarm(alarm)
    }
    
    public func deleteAlarm(alarmId: UUID) async throws {
        try await alarmDataService.deleteAlarm(id: alarmId)
    }
    
    public func toggleAlarm(alarmId: UUID, isEnabled: Bool) async throws {
        try await alarmDataService.toggleAlarm(id: alarmId, isEnabled: isEnabled)
    }
}
