import Foundation
import Supabase
import SupabaseCoreInterface
import MemosDomainInterface

public final class MemosServiceImpl: MemosService {

    private let client: SupabaseClient
    private let supabaseService: SupabaseService

    public init(
        supabaseService: SupabaseService
    ) {
        self.client = supabaseService.client
        self.supabaseService = supabaseService
    }

    public func createMemo(_ memo: MemosEntity) async throws {
        let dto = MemosDTO(from: memo)

        try await client
            .from("memos")
            .insert(dto)
            .execute()
    }
    
    public func updateMemo(_ memo: MemosEntity) async throws {
        let dto = MemosDTO(from: memo)
        
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
    
    public func getMemo(id: UUID) async throws -> MemosEntity {
        let memo: MemosDTO = try await client
            .from("memos")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return memo.toEntity()
    }
    
    public func getMemos(userId: UUID) async throws -> [MemosEntity] {
        let memos: [MemosDTO] = try await client
            .from("memos")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return memos.map { $0.toEntity() }
    }
    
    public func searchMemos(userId: UUID, keyword: String) async throws -> [MemosEntity] {
        let memos: [MemosDTO] = try await client
            .from("memos")
            .select()
            .eq("user_id", value: userId.uuidString)
            .or("title.ilike.%\(keyword)%,description.ilike.%\(keyword)%")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return memos.map { $0.toEntity() }
    }

    public func getMemosByAlarmId(alarmId: UUID) async throws -> [MemosEntity] {
        let memos: [MemosDTO] = try await client
            .from("memos")
            .select()
            .eq("alarm_id", value: alarmId.uuidString)
            .single()
            .execute()
            .value
        return memos.map { $0.toEntity() }
    }
    
    public func getMemosByScheduleId(scheduleId: UUID) async throws -> [MemosEntity] {
        let memos: [MemosDTO] = try await client
            .from("memos")
            .select()
            .eq("schedule_id", value: scheduleId.uuidString)
            .single()
            .execute()
            .value
        return memos.map { $0.toEntity() }
    }
}
