import Foundation
import SupabaseCoreInterface
import Supabase
import MemoDomainInterface

public final class SupabaseMemoStorageImpl: SupabaseMemoStorage {

    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func fetchMemos(for userId: UUID) async throws -> [MemoEntity] {
        let response = try await client
            .from("Memos")
            .select()
            .eq("user_id", value: userId)
            .execute()
        return try JSONDecoder().decode([MemoEntity].self, from: response.data)
    }
    
    public func saveMemo(_ memo: MemoEntity) async throws {
        try await client
            .from("Memos")
            .upsert(memo)
            .execute()
    }
    
    public func deleteMemo(id: UUID) async throws {
        try await client
            .from("Memos")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
