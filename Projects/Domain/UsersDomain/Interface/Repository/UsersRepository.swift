import Foundation

public protocol UserRepository {
    func fetchCurrentUser() async throws -> UserEntity?
    func loginWithOAuth(provider: String, email: String?, displayName: String?) async throws -> UserEntity
    func saveUser(_ user: UserEntity) async throws
    func deleteUser() async throws
    func logout() async throws
}
