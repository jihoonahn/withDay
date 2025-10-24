import Foundation
import AlarmExecutionDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class AlarmExecutionRepositoryImpl: AlarmExecutionRepository {
    private let alarmExecutionService: AlarmExecutionService
    
    public init(alarmExecutionService: AlarmExecutionService) {
        self.alarmExecutionService = alarmExecutionService
    }
    
    public func fetchAll(userId: UUID, date: Date) async throws -> [AlarmExecutionEntity] {
        let models = try await alarmExecutionService.fetchExecutions(userId: userId)
        
        // 날짜 필터링
        let calendar = Calendar.current
        return models
            .filter { calendar.isDate($0.scheduledTime, inSameDayAs: date) }
            .map { $0.toEntity() }
    }
    
    public func create(_ execution: AlarmExecutionEntity) async throws {
        let model = AlarmExecutionModel(from: execution)
        try await alarmExecutionService.createExecution(model)
    }
    
    public func update(_ execution: AlarmExecutionEntity) async throws {
        let model = AlarmExecutionModel(from: execution)
        try await alarmExecutionService.updateExecution(model)
    }
    
    public func updateStatus(id: UUID, status: String) async throws {
        try await alarmExecutionService.updateExecutionStatus(id: id, status: status)
    }
}

