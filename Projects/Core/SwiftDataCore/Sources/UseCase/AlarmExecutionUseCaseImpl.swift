import Foundation
import AlarmExecutionDomainInterface

@MainActor
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
        // SwiftData에서는 부분 업데이트가 제한적
        // 필요시 전체 execution을 가져와서 업데이트
    }
    
    public func completeExecution(id: UUID) async throws {
        try await alarmExecutionRepository.updateStatus(id: id, status: "completed")
    }
}

