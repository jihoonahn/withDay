import Foundation
import AlarmKit
import AlarmSchedulesCoreInterface
import AlarmsDomainInterface

public final class AlarmScheduleRepositoryImpl: AlarmSchedulesRepository {
    private let service: AlarmSchedulesService
    
    public init(service: AlarmSchedulesService) {
        self.service = service
    }
    
    public func scheduleAlarm(_ alarm: AlarmsEntity) async throws {
        try await service.scheduleAlarm(alarm)
    }
    
    public func cancelAlarm(_ alarmId: UUID) async throws {
        try await service.cancelAlarm(alarmId)
    }
    
    public func updateAlarm(_ alarm: AlarmsEntity) async throws {
        try await service.updateAlarm(alarm)
    }
    
    public func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws {
        try await service.toggleAlarm(alarmId, isEnabled: isEnabled)
    }
    public func stopAlarm(_ alarmId: UUID) async throws {
        try await service.stopAlarm(alarmId)
    }
}
