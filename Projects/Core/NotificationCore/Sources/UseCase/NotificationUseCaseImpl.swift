import Foundation
import NotificationDomainInterface
import AlarmDomainInterface

public final class NotificationUseCaseImpl: NotificationUseCase {
    private let repository: NotificationRepository
    
    public init(repository: NotificationRepository) {
        self.repository = repository
    }
    
    public func loadPreference(userId: UUID) async throws -> NotificationEntity? {
        try await repository.loadPreference(userId: userId)
    }
    
    public func updatePreference(userId: UUID, isEnabled: Bool) async throws {
        let entity = NotificationEntity(isEnabled: isEnabled)
        try await repository.upsertPreference(entity, for: userId)
    }

    public func updatePermissions(enabled: Bool) async {
        await repository.updatePermissions(enabled: enabled)
        if !enabled {
            await repository.clearFallbackNotifications()
        }
    }
    
    public func scheduleFallbackNotifications(for alarms: [AlarmEntity]) async {
        await repository.scheduleFallbackNotifications(for: alarms)
    }
    
    public func clearFallbackNotifications() async {
        await repository.clearFallbackNotifications()
    }
}
