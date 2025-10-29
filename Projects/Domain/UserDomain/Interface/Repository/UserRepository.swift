import Foundation

public protocol UserRepository {
    func fetchCurrentUser() async throws -> UserEntity?
    func loginWithOAuth(provider: String, email: String?, displayName: String?) async throws -> UserEntity
    func saveUser(_ user: UserEntity) async throws
    func updateWakeUpGoal(_ time: Date) async throws
    func updateSleepGoal(_ time: Date) async throws
    func gainExperience(_ amount: Int) async throws -> UserEntity
    func deleteUser() async throws
    func logout() async throws
}
