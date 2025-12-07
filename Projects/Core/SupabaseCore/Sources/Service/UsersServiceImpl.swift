import Foundation
import Supabase
import SupabaseCoreInterface
import UsersDomainInterface

public final class UsersServiceImpl: UsersService {

    private let client: SupabaseClient
    private let supabaseService: SupabaseService

    public init(
        client: SupabaseClient,
        supabaseService: SupabaseService
    ) {
        self.client = client
        self.supabaseService = supabaseService
    }

    public func signInWithGoogle() async throws -> UsersEntity {
        let response = try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "com.googleusercontent.apps.868566453670-5qc711tkdesbaagsdtt0lok38jotlutc:/auth")
        )
        let authUser = response.user

        let users: [UsersDTO] = try await client
            .from("users")
            .select()
            .eq("id", value: authUser.id.uuidString)
            .execute()
            .value

        if let existingUser = users.first {
            return existingUser.toEntity()
        }

        let newUser = UsersEntity(
            id: authUser.id,
            provider: "google",
            email: authUser.email,
            displayName: authUser.userMetadata["full_name"]?.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )

        let created: UsersDTO = try await client
            .from("users")
            .insert(newUser)
            .select()
            .single()
            .execute()
            .value
        
        return created.toEntity()
    }

    public func signInWithApple() async throws -> UsersEntity {
        let response = try await client.auth.signInWithOAuth(
            provider: .apple,
            redirectTo: URL(string: "withday://auth/callback")
        )
        let authUser = response.user

        let users: [UsersDTO] = try await client
            .from("users")
            .select()
            .eq("id", value: authUser.id.uuidString)
            .execute()
            .value

        if let existingUser = users.first {
            return existingUser.toEntity()
        }

        let newUser = UsersEntity(
            id: authUser.id,
            provider: "google",
            email: authUser.email,
            displayName: authUser.userMetadata["full_name"]?.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )

        let created: UsersDTO = try await client
            .from("users")
            .insert(newUser)
            .select()
            .single()
            .execute()
            .value
        
        return created.toEntity()
    }

    public func fetchCurrentUser() async throws -> UsersEntity {
        let session = try await client.auth.session
        let userId = session.user.id
        let user: UsersDTO = try await client
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return user.toEntity()
    }

    public func updateUser(_ user: UsersEntity) async throws {
        let user = UsersDTO(from: user)

        try await client
            .from("users")
            .update(user)
            .eq("id", value: user.id.uuidString)
            .execute()
    }

    public func deleteUser(id: UUID) async throws {
        try await client
            .from("users")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    public func signOut() async throws {
        supabaseService.clearSession()
        try await client.auth.signOut()
    }
}
