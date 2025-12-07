import Foundation
import Supabase
import AlarmExecutionsDomainInterface
import SupabaseCoreInterface
import Helpers

// MARK: - Repository Implementation
public final class AlarmExecutionRepositoryImpl: AlarmExecutionsRepository {

    private let alarmExecutionsService: AlarmExecutionsService

    public init(alarmExecutionsService: AlarmExecutionsService) {
        self.alarmExecutionsService = alarmExecutionsService
    }

    public func startExecution(alarmId: UUID) async throws -> AlarmExecutionsEntity {
        return try await alarmExecutionsService.startExecution(alarmId: alarmId)
    }
    
    public func updateExecution(_ execution: AlarmExecutionsEntity) async throws {
        try await alarmExecutionsService.updateExecution(execution)
    }
    
    public func completeExecution(id: UUID) async throws {
        try await alarmExecutionsService.completeExecution(id: id)
    }
}
