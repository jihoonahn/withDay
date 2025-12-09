import Foundation
import NotificationDomainInterface
import NotificationCoreInterface
import AlarmsDomainInterface

public final class NotificationRepositoryImpl: NotificationRepository {
    private let service: NotificationService
    
    public init(service: NotificationService) {
        self.service = service
    }
    
    public func loadPreference(userId: UUID) async throws -> NotificationEntity? {
        guard let isEnabled = try await service.loadIsEnabled() else {
            return nil
        }
        return NotificationEntity(isEnabled: isEnabled)
    }
    
    public func upsertPreference(_ entity: NotificationEntity, for userId: UUID) async throws {
        try await service.saveIsEnabled(entity.isEnabled)
    }

    public func updatePermissions(enabled: Bool) async {
        await service.updatePermissions(enabled: enabled)
    }
    
    public func scheduleFallbackNotifications(for alarms: [AlarmsEntity]) async {
        await service.scheduleFallbackNotifications(for: alarms)
    }
    
    public func clearFallbackNotifications() async {
        await service.clearFallbackNotifications()
    }
}
