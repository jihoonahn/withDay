import Foundation
import Supabase
import SupabaseCoreInterface
import AlarmExecutionsDomainInterface

public final class AlarmExecutionsServiceImpl: AlarmExecutionsService {

    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func startExecution(alarmId: UUID) async throws -> AlarmExecutionsEntity {
        let session = try await client.auth.session
        let userId = session.user.id
        let execution = AlarmExecutionsEntity(
            id: UUID(),
            userId: userId,
            alarmId: alarmId,
            scheduledTime: Date(),
            triggeredTime: nil,
            motionDetectedTime: nil,
            completedTime: nil,
            motionCompleted: false,
            motionAttempts: 0,
            motionData: Data(),
            wakeConfidence: nil,
            postureChanges: nil,
            snoozeCount: 0,
            totalWakeDuration: nil,
            status: "scheduled",
            viewedMemoIds: [],
            createdAt: Date(),
            isMoving: false
        )
        
        let dto = AlarmExecutionsDTO(from: execution)

        let created: AlarmExecutionsDTO = try await client
            .from("alarm_executions")
            .insert(dto)
            .select()
            .single()
            .execute()
            .value

        return created.toEntity()
    }
    
    public func updateExecution(_ execution: AlarmExecutionsEntity) async throws {
        let dto = AlarmExecutionsDTO(from: execution)

        try await client
            .from("alarm_executions")
            .update(dto)
            .eq("id", value: execution.id.uuidString)
            .execute()
    }
    
    public func completeExecution(id: UUID) async throws {
        let execution: AlarmExecutionsDTO = try await client
            .from("alarm_executions")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        var updatedExecution = execution.toEntity()
        updatedExecution.status = "completed"
        updatedExecution.completedTime = Date()
        
        let updateDto = AlarmExecutionsDTO(from: updatedExecution)
        
        try await client
            .from("alarm_executions")
            .update(updateDto)
            .eq("id", value: id.uuidString)
            .execute()
    }
}
