import Foundation
import AlarmScheduleDomainInterface

public final class AlarmScheduleUseCaseImpl: AlarmScheduleUseCase {

    private let repository: AlarmScheduleRepository
    
    public init(repository: AlarmScheduleRepository) {
        self.repository = repository
    }

    public func scheduleAlarm(_ alarm: AlarmScheduleEntity) async throws {
        try await repository.scheduleAlarm(alarm)
    }
    
    public func cancelAlarm(_ alarmId: UUID) async throws {
        try await repository.cancelAlarm(alarmId)
    }
    
    public func updateAlarm(_ alarm: AlarmScheduleEntity) async throws {
        try await repository.updateAlarm(alarm)
    }
    
    public func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws {
        try await repository.toggleAlarm(alarmId, isEnabled: isEnabled)
    }
    
    public func stopAlarm(_ alarmId: UUID) async {
        await repository.stopAlarm(alarmId)
    }
}
