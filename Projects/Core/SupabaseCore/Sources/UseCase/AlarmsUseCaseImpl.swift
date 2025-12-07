import Foundation
import AlarmsDomainInterface

public final class AlarmsUseCaseImpl: AlarmsUseCase {
    private let alarmsRepository: AlarmsRepository
    
    public init(alarmsRepository: AlarmsRepository) {
        self.alarmsRepository = alarmsRepository
    }
    
    public func fetchAll() async throws -> [AlarmsEntity] {
        return try await alarmsRepository.fetchAlarms()
    }
    
    public func create(_ alarm: AlarmsEntity) async throws {
        try await alarmsRepository.createAlarm(alarm)
    }
    
    public func update(_ alarm: AlarmsEntity) async throws {
        try await alarmsRepository.updateAlarm(alarm)
    }
    
    public func delete(id: UUID) async throws {
        try await alarmsRepository.deleteAlarm(alarmId: id)
    }
    
    public func toggle(id: UUID, isEnabled: Bool) async throws {
        try await alarmsRepository.toggleAlarm(alarmId: id, isEnabled: isEnabled)
    }
}
