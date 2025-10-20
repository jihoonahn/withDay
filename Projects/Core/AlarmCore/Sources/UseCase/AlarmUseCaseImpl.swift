import Foundation
import BaseDomain
import AlarmCoreInterface
import AlarmDomainInterface

public final class AlarmUseCaseImpl: AlarmUseCase {

    private let repository: AlarmRepository
    private let localStorage: LocalAlarmStorage
    private let scheduler: AlarmScheduler

    public init(repository: AlarmRepository, localStorage: LocalAlarmStorage, scheduler: AlarmScheduler) {
        self.repository = repository
        self.localStorage = localStorage
        self.scheduler = scheduler
    }

    public func getAlarms(for userId: UUID) -> [AlarmEntity] {
        do {
            let localAlarms = try localStorage.fetchAll()
            return localAlarms.map { local in
                local.toDomain()
            }
        } catch {
            print("Error fetching local alarms: \(error)")
            return []
        }
    }

    public func addAlarm(_ alarm: AlarmEntity) {
        Task {
            do {
                try await repository.saveAlarm(alarm)
                try localStorage.insert(
                    LocalAlarmEntity.fromDomain(alarm)
                )
                if let date = alarm.time.date {
                    scheduler.scheduleAlarm(at: date, title: alarm.title)
                }
            } catch {
                print("Error adding alarm: \(error)")
            }
        }
    }

    public func syncAlarms(for userId: UUID) async throws {
        try await repository.syncAlarms(for: userId)
        let alarms = try await repository.fetchAlarms(for: userId)
        for alarm in alarms {
            if let date = alarm.time.date {
                scheduler.scheduleAlarm(at: date, title: alarm.title)
            }
        }
    }
}
