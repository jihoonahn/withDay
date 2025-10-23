import Foundation
import Supabase
import SupabaseCoreInterface
import MotionRawDataDomainInterface

public final class MotionRawDataServiceImpl: MotionRawDataService {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func fetchMotionData(for executionId: UUID) async throws -> [MotionRawDataEntity] {
        let motionData: [MotionRawDataDTO] = try await client
            .from("motion_raw_data")
            .select()
            .eq("execution_id", value: executionId.uuidString)
            .order("timestamp")
            .execute()
            .value
        
        return motionData.map { $0.toEntity() }
    }
    
    public func createMotionData(_ data: MotionRawDataEntity) async throws {
        let dto = MotionRawDataDTO(from: data)
        
        try await client
            .from("motion_raw_data")
            .insert(dto)
            .execute()
    }
    
    public func deleteMotionData(for executionId: UUID) async throws {
        try await client
            .from("motion_raw_data")
            .delete()
            .eq("execution_id", value: executionId.uuidString)
            .execute()
    }
}
