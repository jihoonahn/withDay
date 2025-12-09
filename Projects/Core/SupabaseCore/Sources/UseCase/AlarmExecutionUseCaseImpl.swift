import Foundation
import AlarmExecutionsDomainInterface

public final class AlarmExecutionsUseCaseImpl: AlarmExecutionsUseCase {
    private let alarmExecutionRepository: AlarmExecutionsRepository
    
    public init(alarmExecutionRepository: AlarmExecutionsRepository) {
        self.alarmExecutionRepository = alarmExecutionRepository
    }
    
    public func startExecution(userId: UUID, alarmId: UUID) async throws -> AlarmExecutionsEntity {
        return try await alarmExecutionRepository.startExecution(userId: userId, alarmId: alarmId)
    }
    
    public func updateExecution(_ execution: AlarmExecutionsEntity) async throws {
        try await alarmExecutionRepository.updateExecution(execution)
    }
    
    public func completeExecution(id: UUID) async throws {
        try await alarmExecutionRepository.completeExecution(id: id)
    }
}
