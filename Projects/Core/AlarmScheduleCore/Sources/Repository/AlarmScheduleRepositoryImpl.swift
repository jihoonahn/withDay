import Foundation
import AlarmScheduleCoreInterface
import AlarmScheduleDomainInterface

public final class AlarmScheduleRepositoryImpl: AlarmScheduleRepository {

    private let service: AlarmScheduleService

    public init(service: AlarmScheduleService) {
        self.service = service
    }

    public func scheduleAlarm(_ alarm: AlarmScheduleEntity) async throws {
        try await service.scheduleAlarm(alarm)
    }
    
    public func cancelAlarm(_ alarmId: UUID) async throws {
        try await service.cancelAlarm(alarmId)
    }
    
    public func updateAlarm(_ alarm: AlarmScheduleEntity) async throws {
        try await service.updateAlarm(alarm)
    }
    
    public func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws {
        try await service.toggleAlarm(alarmId, isEnabled: isEnabled)
    }
    
    public func stopAlarm(_ alarmId: UUID) async {
        await service.stopAlarm(alarmId)
    }
}

