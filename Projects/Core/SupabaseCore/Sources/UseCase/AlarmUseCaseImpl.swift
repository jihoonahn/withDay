import Foundation
import AlarmDomainInterface

public final class AlarmUseCaseImpl: AlarmUseCase {
    private let alarmRepository: AlarmRepository
    
    public init(alarmRepository: AlarmRepository) {
        self.alarmRepository = alarmRepository
    }
    
    public func fetchAll(userId: UUID) async throws -> [AlarmEntity] {
        return try await alarmRepository.fetchAlarms(userId: userId)
    }
    
    public func create(_ alarm: AlarmEntity) async throws {
        try await alarmRepository.createAlarm(alarm)
    }
    
    public func update(_ alarm: AlarmEntity) async throws {
        try await alarmRepository.updateAlarm(alarm)
    }
    
    public func delete(id: UUID) async throws {
        try await alarmRepository.deleteAlarm(alarmId: id)
    }
    
    public func toggle(id: UUID, isEnabled: Bool) async throws {
        try await alarmRepository.toggleAlarm(alarmId: id, isEnabled: isEnabled)
    }
}
