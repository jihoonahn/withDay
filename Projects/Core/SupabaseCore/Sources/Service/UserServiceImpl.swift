import Foundation
import Supabase
import SupabaseCoreInterface
import UserDomainInterface
import Utility

public final class UserServiceImpl: UserService {

    private let client: SupabaseClient
    
    public init(client: SupabaseClient) {
        self.client = client
    }
    
    public func signInWithGoogle() async throws -> UserEntity {
        let response = try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "com.googleusercontent.apps.868566453670-5qc711tkdesbaagsdtt0lok38jotlutc:/auth")
        )
        let authUser = response.user
        
        let users: [UserDTO] = try await client
            .from("users")
            .select()
            .eq("id", value: authUser.id.uuidString)
            .execute()
            .value
        
        if let existingUser = users.first {
            return existingUser.toEntity()
        }
        
        let newUser = UserDTO(
            id: authUser.id,
            provider: "google",
            email: authUser.email,
            displayName: authUser.userMetadata["full_name"]?.rawValue,
            wakeUpGoal: nil,
            sleepGoal: nil,
            notificationEnabled: true,
            soundVolume: 70,
            hapticEnabled: true,
            level: 1,
            experience: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let created: UserDTO = try await client
            .from("users")
            .insert(newUser)
            .select()
            .single()
            .execute()
            .value
        
        return created.toEntity()
    }
    
    public func signInWithApple() async throws -> UserEntity {
        let response = try await client.auth.signInWithOAuth(
            provider: .apple,
            redirectTo: URL(string: "withday://auth/callback")
        )
        let authUser = response.user
        
        let users: [UserDTO] = try await client
            .from("users")
            .select()
            .eq("id", value: authUser.id.uuidString)
            .execute()
            .value
        
        if let existingUser = users.first {
            return existingUser.toEntity()
        }
        
        let newUser = UserDTO(
            id: authUser.id,
            provider: "apple",
            email: authUser.email,
            displayName: authUser.userMetadata["full_name"]?.rawValue,
            wakeUpGoal: nil,
            sleepGoal: nil,
            notificationEnabled: true,
            soundVolume: 70,
            hapticEnabled: true,
            level: 1,
            experience: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let created: UserDTO = try await client
            .from("users")
            .insert(newUser)
            .select()
            .single()
            .execute()
            .value
        
        return created.toEntity()
    }
    
    public func fetchUser(id: UUID) async throws -> UserEntity {
        let user: UserDTO = try await client
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return user.toEntity()
    }
    
    public func updateUser(_ user: UserEntity) async throws {
        let userDTO = UserDTO(from: user)
        
        try await client
            .from("users")
            .update(userDTO)
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
        try await client.auth.signOut(scope: .global)
    }
}
