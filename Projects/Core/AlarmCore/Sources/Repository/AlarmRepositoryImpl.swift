import Foundation
import AlarmDomainInterface
import AlarmCoreInterface

public final class AlarmRepositoryImpl: AlarmRepository {
    private let local: LocalAlarmRepositoryImpl
    private let remote: SupabaseAlarmRepositoryImpl

    public init(local: LocalAlarmRepositoryImpl, remote: SupabaseAlarmRepositoryImpl) {
        self.local = local
        self.remote = remote
    }

    public func fetchAlarms(for userId: UUID) async throws -> [AlarmEntity] {
        return try await local.fetchAlarms(for: userId)
    }
    
    public func saveAlarm(_ alarm: AlarmEntity) async throws {
        try await local.saveAlarm(alarm)
        try await remote.saveAlarm(alarm)
    }
    
    public func syncAlarms(for userId: UUID) async throws {
        let remoteAlarms = try await remote.fetchAlarms(for: userId)
        let localAlarms = try await local.fetchAlarms(for: userId)

        for alarm in remoteAlarms {
             if !localAlarms.contains(where: { $0.id == alarm.id }) {
                 try await local.saveAlarm(alarm)
             }
        }

        for alarm in localAlarms {
            if !remoteAlarms.contains(where: { $0.id == alarm.id }) {
                try await remote.saveAlarm(alarm)
            }
        }
    }
}
