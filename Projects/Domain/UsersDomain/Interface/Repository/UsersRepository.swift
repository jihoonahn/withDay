import Foundation

public enum UsersRepositoryError: Error {
    case userNotFound
    case unsupportedProvider(String)
}

public protocol UsersRepository: Sendable {
    func fetchCurrentUser() async throws -> UsersEntity?
    func loginWithOAuth(provider: String, email: String?, displayName: String?) async throws -> UsersEntity
    func saveUser(_ user: UsersEntity) async throws
    func deleteUser() async throws
    func logout() async throws
}
