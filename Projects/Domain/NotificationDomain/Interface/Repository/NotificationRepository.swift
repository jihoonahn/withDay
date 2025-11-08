import Foundation

public protocol NotificationPreferenceRepository {
    func loadPreference(userId: UUID) async throws -> NotificationPreferenceEntity?
    func upsertPreference(_ entity: NotificationPreferenceEntity, for userId: UUID) async throws
}
