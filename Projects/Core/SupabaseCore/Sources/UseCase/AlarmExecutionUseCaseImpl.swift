import Foundation
import AlarmExecutionsDomainInterface

public final class AlarmExecutionUseCaseImpl: AlarmExecutionsUseCase {
    private let alarmExecutionRepository: AlarmExecutionsRepository
    
    public init(alarmExecutionRepository: AlarmExecutionsRepository) {
        self.alarmExecutionRepository = alarmExecutionRepository
    }
    
    public func startExecution(alarmId: UUID) async throws -> AlarmExecutionsEntity {
        return try await alarmExecutionRepository.startExecution(alarmId: alarmId)
    }
    
    public func updateExecution(_ execution: AlarmExecutionsEntity) async throws {
        try await alarmExecutionRepository.updateExecution(execution)
    }
    
    public func completeExecution(id: UUID) async throws {
        try await alarmExecutionRepository.completeExecution(id: id)
    }
}
