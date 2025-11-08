import Foundation

public protocol NotificationUseCase {
    func loadPreference(userId: UUID) async throws -> NotificationPreferenceEntity?
    func updatePreference(userId: UUID, isEnabled: Bool) async throws
}
