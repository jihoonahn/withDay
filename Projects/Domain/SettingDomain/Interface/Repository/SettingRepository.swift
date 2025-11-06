import Foundation

public protocol SettingRepository {
    func fetch(userId: UUID) async throws -> SettingEntity?
    func save(_ setting: SettingEntity) async throws
    func update(_ setting: SettingEntity) async throws
}
