import Foundation
import Supabase
import SupabaseCoreInterface
import MotionDomainInterface

public final class MotionServiceImpl: MotionService {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func fetchMotions(for executionId: UUID) async throws -> [MotionEntity] {
        let motionData: [MotionDTO] = try await client
            .from("motion_raw_data")
            .select()
            .eq("execution_id", value: executionId.uuidString)
            .order("timestamp")
            .execute()
            .value
        
        return motionData.map { $0.toEntity() }
    }
    
    public func createMotion(_ motion: MotionEntity) async throws {
        let dto = MotionDTO(from: motion)
        
        try await client
            .from("motion_raw_data")
            .insert(dto)
            .execute()
    }
    
    public func deleteMotions(for executionId: UUID) async throws {
        try await client
            .from("motion_raw_data")
            .delete()
            .eq("execution_id", value: executionId.uuidString)
            .execute()
    }
}

