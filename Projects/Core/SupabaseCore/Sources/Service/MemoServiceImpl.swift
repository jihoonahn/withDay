import Foundation
import Supabase
import SupabaseCoreInterface
import MemoDomainInterface

public final class MemoServiceImpl: MemoService {
    private let client: SupabaseClient
    
    public init(client: SupabaseClient) {
        self.client = client
    }
    
    public func fetchMemos(for userId: UUID) async throws -> [MemoEntity] {
        let memos: [MemoDTO] = try await client
            .from("memos")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return memos.map { $0.toEntity() }
    }
    
    public func fetchMemosByAlarm(alarmId: UUID) async throws -> [MemoEntity] {
        let memos: [MemoDTO] = try await client
            .from("memos")
            .select()
            .eq("alarm_id", value: alarmId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return memos.map { $0.toEntity() }
    }
    
    public func createMemo(_ memo: MemoEntity) async throws {
        let dto = MemoDTO(from: memo)
        
        try await client
            .from("memos")
            .insert(dto)
            .execute()
    }
    
    public func updateMemo(_ memo: MemoEntity) async throws {
        let dto = MemoDTO(from: memo)
        
        try await client
            .from("memos")
            .update(dto)
            .eq("id", value: memo.id.uuidString)
            .execute()
    }
    
    public func deleteMemo(id: UUID) async throws {
        try await client
            .from("memos")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
