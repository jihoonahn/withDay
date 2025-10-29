import Foundation

public protocol UserUseCase {
    func login(provider: String, email: String?, displayName: String?) async throws -> UserEntity
    func getCurrentUser() async throws -> UserEntity?
    func updateGoals(wakeUp: Date?, sleep: Date?) async throws
    func gainExperience(amount: Int) async throws -> UserEntity
    func deleteUser() async throws
    func logout() async throws
}
