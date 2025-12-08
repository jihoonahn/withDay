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
    
    public func getMemos() async throws -> [MemosEntity] {
        let session = try await client.auth.session
        let userId = session.user.id
        let memos: [MemosDTO] = try await client
            .from("memos")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return memos.map { $0.toEntity() }
    }
    
    public func searchMemos(keyword: String) async throws -> [MemosEntity] {
        let session = try await client.auth.session
        let userId = session.user.id
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
}
