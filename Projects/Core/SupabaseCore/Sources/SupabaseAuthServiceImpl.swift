import Foundation
import SupabaseCoreInterface
import Supabase

public final class SupabaseAuthServiceImpl: SupabaseAuthService {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func signInWithOAuth(provider: Provider) async throws -> UUID {
        let session = try await client.auth.signInWithOAuth(provider: provider)
        return session.user.id
    }

    public func currentUserId() -> UUID? {
        client
            .auth
            .currentUser?
            .id
    }
}
