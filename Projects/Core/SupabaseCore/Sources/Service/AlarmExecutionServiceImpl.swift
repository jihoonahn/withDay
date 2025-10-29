import Foundation
import Supabase
import SupabaseCoreInterface
import AlarmExecutionDomainInterface

public final class AlarmExecutionServiceImpl: AlarmExecutionService {

    private let client: SupabaseClient
    
    public init(client: SupabaseClient) {
        self.client = client
    }
    
    public func fetchExecutions(for userId: UUID) async throws -> [AlarmExecutionEntity] {
        let executions: [AlarmExecutionDTO] = try await client
            .from("alarm_executions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("scheduled_time", ascending: false)
            .execute()
            .value
        
        return executions.map { $0.toEntity() }
    }
    
    public func fetchExecutionsByAlarm(alarmId: UUID) async throws -> [AlarmExecutionEntity] {
        let executions: [AlarmExecutionDTO] = try await client
            .from("alarm_executions")
            .select()
            .eq("alarm_id", value: alarmId.uuidString)
            .order("scheduled_time", ascending: false)
            .execute()
            .value
        
        return executions.map { $0.toEntity() }
    }
    
    public func createExecution(_ execution: AlarmExecutionEntity) async throws {
        let dto = AlarmExecutionDTO(from: execution)
        
        try await client
            .from("alarm_executions")
            .insert(dto)
            .execute()
    }
    
    public func updateExecution(_ execution: AlarmExecutionEntity) async throws {
        let dto = AlarmExecutionDTO(from: execution)
        
        try await client
            .from("alarm_executions")
            .update(dto)
            .eq("id", value: execution.id.uuidString)
            .execute()
    }

    public func deleteExecution(id: UUID) async throws {
        try await client
            .from("alarm_executions")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    public func updateExecutionStatus(id: UUID, status: String) async throws {
        try await client
            .from("alarm_executions")
            .update(["status": status])
            .eq("id", value: id)
            .execute()
    }

    public func updateMotion(id: UUID, motionData: Data, wakeConfidence: Double, postureChanges: Int, isMoving: Bool) async throws {
  
        struct MotionUpdate: Encodable {
            let motionData: Data
            let wakeConfidence: Double
            let postureChanges: Int
            let isMoving: Bool
        }

        let updatePayload = MotionUpdate(
            motionData: motionData,
            wakeConfidence: wakeConfidence,
            postureChanges: postureChanges,
            isMoving: isMoving
        )

        try await client
            .from("alarm_executions")
            .update(updatePayload)
            .eq("id", value: id)
            .execute()
    }
}
