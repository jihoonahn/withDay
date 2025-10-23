import Foundation
import AlarmDomainInterface
import SupabaseCoreInterface

public final class AlarmRepositoryImpl: AlarmRepository {
    private let alarmService: AlarmService
    
    public init(alarmService: AlarmService) {
        self.alarmService = alarmService
    }
    
    public func fetchAlarms(userId: UUID) async throws -> [AlarmEntity] {
        return try await alarmService.fetchAlarms(for: userId)
    }
    
    public func createAlarm(_ alarm: AlarmEntity) async throws {
        try await alarmService.createAlarm(alarm)
    }
    
    public func updateAlarm(_ alarm: AlarmEntity) async throws {
        try await alarmService.updateAlarm(alarm)
    }
    
    public func deleteAlarm(alarmId: UUID) async throws {
        try await alarmService.deleteAlarm(id: alarmId)
    }
    
    public func toggleAlarm(alarmId: UUID, isEnabled: Bool) async throws {
        try await alarmService.toggleAlarm(id: alarmId, isEnabled: isEnabled)
    }
}

public enum AlarmRepositoryError: Error {
    case alarmNotFound
}
