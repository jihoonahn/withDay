import Foundation
import AlarmDomainInterface
import AlarmCoreInterface
import Dependency

public final class AlarmUseCaseImpl: AlarmUseCase {
    private let alarmRepository: AlarmRepository
    private var alarmScheduler: AlarmSchedulerService? {
        DIContainer.shared.isRegistered(AlarmSchedulerService.self) 
            ? DIContainer.shared.resolve(AlarmSchedulerService.self) 
            : nil
    }
    
    public init(alarmRepository: AlarmRepository) {
        self.alarmRepository = alarmRepository
    }
    
    public func fetchAll(userId: UUID) async throws -> [AlarmEntity] {
        return try await alarmRepository.fetchAlarms(userId: userId)
    }
    
    public func create(_ alarm: AlarmEntity) async throws {
        try await alarmRepository.createAlarm(alarm)
        
        if alarm.isEnabled {
            alarmScheduler?.scheduleAlarm(alarm)
        }
    }
    
    public func update(_ alarm: AlarmEntity) async throws {
        try await alarmRepository.updateAlarm(alarm)
        
        alarmScheduler?.cancelAlarm(alarm.id)
        if alarm.isEnabled {
            alarmScheduler?.scheduleAlarm(alarm)
        }
    }
    
    public func delete(id: UUID) async throws {
        try await alarmRepository.deleteAlarm(alarmId: id)
        
        alarmScheduler?.cancelAlarm(id)
    }
    
    public func toggle(id: UUID, isEnabled: Bool) async throws {
        try await alarmRepository.toggleAlarm(alarmId: id, isEnabled: isEnabled)
        
        if isEnabled {
            // TODO: 알람 스케줄링 필요 시 구현
        } else {
            alarmScheduler?.cancelAlarm(id)
        }
    }
}
