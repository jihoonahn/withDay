import Foundation
import UserSettingsDomainInterface
import SwiftDataCoreInterface

public final class UserSettingsRepositoryImpl: UserSettingsRepository {

    private let userSettingsService: SwiftDataCoreInterface.UserSettingsService

    public init(userSettingsService: SwiftDataCoreInterface.UserSettingsService) {
        self.userSettingsService = userSettingsService
    }

    public func fetchSettings(userId: UUID) async throws -> UserSettingsEntity? {
        if let model = try await userSettingsService.fetchSettings(userId: userId) {
            return UserSettingsDTO.toEntity(from: model)
        }
        return nil
    }

    public func updateSettings(_ settings: UserSettingsEntity) async throws {
        let model = UserSettingsDTO.toModel(from: settings)
        try await userSettingsService.updateSettings(model)
    }
}
