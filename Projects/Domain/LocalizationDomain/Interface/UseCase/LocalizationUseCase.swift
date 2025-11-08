import Foundation

public protocol LocalizationUseCase {
    func loadPreferredLanguage(userId: UUID) async throws -> LocalizationEntity?
    func savePreferredLanguage(userId: UUID, languageCode: String) async throws
}
