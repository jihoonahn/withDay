import Foundation
import UserDomainInterface

public protocol UserService {
    func signInWithGoogle() async throws -> UserEntity
    func signInWithApple() async throws -> UserEntity
    func fetchUser(id: UUID) async throws -> UserEntity
    func updateUser(_ user: UserEntity) async throws
    func deleteUser(id: UUID) async throws
    func signOut() async throws
}
