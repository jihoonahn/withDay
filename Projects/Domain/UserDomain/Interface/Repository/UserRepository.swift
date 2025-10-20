import Foundation

public protocol UserRepository {
    func signInOAuth(provider: String) async throws -> UserEntity
    func currentUser() -> UserEntity?
}
