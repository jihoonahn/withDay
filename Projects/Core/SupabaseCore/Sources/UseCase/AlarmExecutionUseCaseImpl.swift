import Foundation
import AlarmExecutionDomainInterface

public final class AlarmExecutionUseCaseImpl: AlarmExecutionUseCase {
    private let alarmExecutionRepository: AlarmExecutionRepository
    
    public init(alarmExecutionRepository: AlarmExecutionRepository) {
        self.alarmExecutionRepository = alarmExecutionRepository
    }
    
    public func getExecutions(userId: UUID, date: Date) async throws -> [AlarmExecutionEntity] {
        return try await alarmExecutionRepository.fetchAll(userId: userId, date: date)
    }
    
    public func saveExecution(_ execution: AlarmExecutionEntity) async throws {
        if execution.createdAt == Date() {
            try await alarmExecutionRepository.create(execution)
        } else {
            try await alarmExecutionRepository.update(execution)
        }
    }
    
    public func markMotionDetected(id: UUID, motionData: [String: Any], wakeConfidence: Double) async throws {
        // Note: 현재 구현은 제한적입니다.
        // 실제로는 해당 execution을 가져와서 motionDetectedTime과 motionData를 업데이트해야 합니다.
        // 이를 위해서는 AlarmExecutionService에 부분 업데이트 메서드가 필요합니다.
    }
    
    public func completeExecution(id: UUID) async throws {
        try await alarmExecutionRepository.updateStatus(id: id, status: "completed")
    }
}
