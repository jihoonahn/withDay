import Foundation
import AlarmKit
import AlarmsDomainInterface

public final class AlarmScheduleUseCaseImpl: AlarmSchedulesUseCase {
    private let repository: AlarmSchedulesRepository

    public init(repository: AlarmSchedulesRepository) {
        self.repository = repository
    }

    public func scheduleAlarm(_ alarm: AlarmsEntity) async throws {
        try await repository.scheduleAlarm(alarm)
    }

    public func cancelAlarm(_ alarmId: UUID) async throws {
        try await repository.cancelAlarm(alarmId)
    }

    public func updateAlarm(_ alarm: AlarmsEntity) async throws {
        try await repository.updateAlarm(alarm)
    }

    public func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws {
        try await repository.toggleAlarm(alarmId, isEnabled: isEnabled)
    }

    public func stopAlarm(_ alarmId: UUID) async throws {
        try await repository.stopAlarm(alarmId)
    }
}
