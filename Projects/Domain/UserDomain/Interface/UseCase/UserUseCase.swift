import Foundation

public protocol UserUseCase {
    func loginWithOAuth(provider: String) async throws -> UserEntity
    func getCurrentUser() -> UserEntity?
}
