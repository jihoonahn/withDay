import Foundation
import UsersDomainInterface

public protocol UsersService: Sendable {
    func signInWithGoogle() async throws -> UsersEntity
    func signInWithApple() async throws -> UsersEntity
    func fetchCurrentUser() async throws -> UsersEntity
    func updateUser(_ user: UsersEntity) async throws
    func deleteUser(id: UUID) async throws
    func signOut() async throws
}
