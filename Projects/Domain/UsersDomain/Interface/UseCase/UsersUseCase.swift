import Foundation

public protocol UsersUseCase: Sendable {
    func login(provider: String, email: String?, displayName: String?) async throws -> UsersEntity
    func updateUser(_ user: UsersEntity) async throws
    func getCurrentUser() async throws -> UsersEntity?
    func deleteUser() async throws
    func logout() async throws
}
