import Foundation

public protocol UserUseCase {
    func login(provider: String, email: String?, displayName: String?) async throws -> UserEntity
    func updateUser(_ user: UserEntity) async throws
    func getCurrentUser() async throws -> UserEntity?
    func deleteUser() async throws
    func logout() async throws
}
