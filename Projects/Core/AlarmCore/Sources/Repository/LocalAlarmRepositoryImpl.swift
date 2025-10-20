import Foundation
import AlarmDomainInterface
import AlarmCoreInterface

public final class LocalAlarmRepositoryImpl: AlarmRepository {

    private let storage: LocalAlarmStorage

    public init(storage: LocalAlarmStorage) {
        self.storage = storage
    }

    public func fetchAlarms(for userId: UUID) async throws -> [AlarmEntity] {
        do {
            let localAlarms = try storage.fetchAll()
            return localAlarms
                .filter { $0.userId == userId }
                .map { $0.toDomain() }
        } catch {
            print("Error fetching local alarms: \(error)")
            return []
        }
    }
    
    public func saveAlarm(_ alarm: AlarmEntity) async throws {
        let local = LocalAlarmEntity.fromDomain(alarm)
        try storage.insert(local)
    }
    
    public func syncAlarms(for userId: UUID) async throws {}
}
