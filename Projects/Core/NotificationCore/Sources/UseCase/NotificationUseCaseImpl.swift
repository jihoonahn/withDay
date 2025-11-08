import Foundation
import NotificationDomainInterface

public final class NotificationUseCaseImpl: NotificationUseCase {
    private let repository: NotificationPreferenceRepository
    
    public init(repository: NotificationPreferenceRepository) {
        self.repository = repository
    }
    
    public func loadPreference(userId: UUID) async throws -> NotificationPreferenceEntity? {
        try await repository.loadPreference(userId: userId)
    }
    
    public func updatePreference(userId: UUID, isEnabled: Bool) async throws {
        let entity = NotificationPreferenceEntity(isEnabled: isEnabled)
        try await repository.upsertPreference(entity, for: userId)
    }
}

