import Foundation
import Supabase
import UsersDomainInterface
import SupabaseCoreInterface

// MARK: - Repository Implementation
public final class UsersRepositoryImpl: UsersRepository {
    private let usersService: UsersService
    
    public init(usersService: UsersService) {
        self.usersService = usersService
    }
    
    public func fetchCurrentUser() async throws -> UsersEntity? {
        do {
            return try await usersService.fetchCurrentUser()
        } catch {
            // 세션이 없거나 만료된 경우 nil을 반환
            // Supabase AuthError 또는 네트워크 오류 등의 경우 nil 반환
            print("⚠️ [UsersRepositoryImpl] 세션을 가져오는 중 오류 발생: \(error)")
            return nil
        }
    }
    
    public func loginWithOAuth(provider: String, email: String?, displayName: String?) async throws -> UsersEntity {
        switch provider.lowercased() {
        case "google":
            return try await usersService.signInWithGoogle()
        case "apple":
            return try await usersService.signInWithApple()
        default:
            throw UsersRepositoryError.unsupportedProvider(provider)
        }
    }
    
    public func saveUser(_ user: UsersEntity) async throws {
        try await usersService.updateUser(user)
    }
    
    public func deleteUser() async throws {
        guard let currentUser = try await fetchCurrentUser() else {
            throw UsersRepositoryError.userNotFound
        }
        try await usersService.deleteUser(id: currentUser.id)
    }
    
    public func logout() async throws {
        try await usersService.signOut()
    }
}
