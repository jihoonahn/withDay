import Foundation
import AlarmDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class AlarmRepositoryImpl: AlarmRepository {
    private let alarmService: AlarmService
    
    public init(alarmService: AlarmService) {
        self.alarmService = alarmService
    }
    
    public func fetchAlarms(userId: UUID) async throws -> [AlarmEntity] {
        let models = try await alarmService.fetchAlarms(userId: userId)
        return models.map { $0.toEntity() }
    }
    
    public func createAlarm(_ alarm: AlarmEntity) async throws {
        let model = AlarmModel(from: alarm)
        try await alarmService.saveAlarm(model)
    }
    
    public func updateAlarm(_ alarm: AlarmEntity) async throws {
        let model = AlarmModel(from: alarm)
        try await alarmService.updateAlarm(model)
    }
    
    public func deleteAlarm(alarmId: UUID) async throws {
        try await alarmService.deleteAlarm(id: alarmId)
    }
    
    public func toggleAlarm(alarmId: UUID, isEnabled: Bool) async throws {
        try await alarmService.toggleAlarm(id: alarmId, isEnabled: isEnabled)
    }
}

