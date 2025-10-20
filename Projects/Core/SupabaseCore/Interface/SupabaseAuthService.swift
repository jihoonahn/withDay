import Foundation
import Supabase

public protocol SupabaseAuthService {
    func signInWithOAuth(provider: Provider) async throws -> UUID
    func currentUserId() -> UUID?
}
