import Foundation
import AlarmsDomainInterface
import SwiftDataCoreInterface

public final class AlarmRepositoryImpl: AlarmsRepository {
    private let alarmService: SwiftDataCoreInterface.AlarmService
    
    public init(alarmService: SwiftDataCoreInterface.AlarmService) {
        self.alarmService = alarmService
    }
    
    public func fetchAlarms(userId: UUID) async throws -> [AlarmsEntity] {
        let models = try await alarmService.fetchAlarms(userId: userId)
        return models.map { AlarmsDTO.toEntity(from: $0) }
    }
    
    public func createAlarm(_ alarm: AlarmsEntity) async throws {
        let model = AlarmsDTO.toModel(from: alarm)
        try await alarmService.saveAlarm(model)
    }
    
    public func updateAlarm(_ alarm: AlarmsEntity) async throws {
        let model = AlarmsDTO.toModel(from: alarm)
        try await alarmService.updateAlarm(model)
    }
    
    public func deleteAlarm(alarmId: UUID) async throws {
        try await alarmService.deleteAlarm(id: alarmId)
    }
    
    public func toggleAlarm(alarmId: UUID, isEnabled: Bool) async throws {
        try await alarmService.toggleAlarm(id: alarmId, isEnabled: isEnabled)
    }
}
