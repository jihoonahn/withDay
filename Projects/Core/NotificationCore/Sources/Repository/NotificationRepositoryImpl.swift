import Foundation
import NotificationDomainInterface
import NotificationCoreInterface

public final class NotificationRepositoryImpl: NotificationPreferenceRepository {
    private let service: NotificationService
    
    public init(service: NotificationService) {
        self.service = service
    }
    
    public func loadPreference(userId: UUID) async throws -> NotificationPreferenceEntity? {
        guard let isEnabled = try await service.loadIsEnabled() else {
            return nil
        }
        return NotificationPreferenceEntity(isEnabled: isEnabled)
    }
    
    public func upsertPreference(_ entity: NotificationPreferenceEntity, for userId: UUID) async throws {
        try await service.saveIsEnabled(entity.isEnabled)
    }
}

