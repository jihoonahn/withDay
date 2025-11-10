import Foundation

public protocol LocalizationRepository {
    func loadPreferredLanguage(userId: UUID) async throws -> LocalizationEntity?
    func savePreferredLanguage(_ entity: LocalizationEntity, for userId: UUID) async throws
    func fetchLocalizationBundle() -> Bundle
    func fetchAvailableLocalizations() async throws -> [LocalizationEntity]
}
