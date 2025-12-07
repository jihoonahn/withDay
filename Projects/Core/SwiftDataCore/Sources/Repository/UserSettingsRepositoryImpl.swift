import Foundation
import UserSettingsDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class UserSettingsRepositoryImpl: UserSettingsRepository {
    private let userSettingsService: SwiftDataCoreInterface.UserSettingsService
    
    public init(userSettingsService: SwiftDataCoreInterface.UserSettingsService) {
        self.userSettingsService = userSettingsService
    }
    
    public func fetchSettings() async throws -> UserSettingsEntity? {
        // SwiftDataCore는 로컬 저장소이므로 첫 번째 설정을 반환
        // 실제로는 userId를 파라미터로 받아야 할 수도 있지만,
        // Domain Interface가 userId를 받지 않으므로 첫 번째 설정 반환
        let models = try await userSettingsService.fetchAllSettings()
        return models.first.map { UserSettingsDTO.toEntity(from: $0) }
    }
    
    public func updateSettings(_ settings: UserSettingsEntity) async throws {
        let model = UserSettingsDTO.toModel(from: settings)
        try await userSettingsService.updateSettings(model)
    }
}

