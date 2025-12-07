import Foundation
import UsersDomainInterface

public final class UsersUseCaseImpl: UsersUseCase {
    private let userRepository: UsersRepository
    
    public init(userRepository: UsersRepository) {
        self.userRepository = userRepository
    }
    
    public func login(provider: String, email: String?, displayName: String?) async throws -> UsersEntity {
        return try await userRepository.loginWithOAuth(
            provider: provider,
            email: email,
            displayName: displayName
        )
    }
    
    public func getCurrentUser() async throws -> UsersEntity? {
        return try await userRepository.fetchCurrentUser()
    }
    
    public func updateUser(_ user: UsersEntity) async throws {
        try await userRepository.saveUser(user)
    }
    
    public func deleteUser() async throws {
        try await userRepository.deleteUser()
    }
    
    public func logout() async throws {
        try await userRepository.logout()
    }
}
