import Foundation
import UserSettingsDomainInterface

public final class UserSettingsUseCaseImpl: UserSettingsUseCase {
    private let userSettingsRepository: UserSettingsRepository
    
    public init(userSettingsRepository: UserSettingsRepository) {
        self.userSettingsRepository = userSettingsRepository
    }
    
    public func getSettings() async throws -> UserSettingsEntity? {
        return try await userSettingsRepository.fetchSettings()
    }
    
    public func updateSettings(_ settings: UserSettingsEntity) async throws {
        try await userSettingsRepository.updateSettings(settings)
    }
}
