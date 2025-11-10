import Foundation
import LocalizationDomainInterface

public final class LocalizationUseCaseImpl: LocalizationUseCase {
    private let repository: LocalizationRepository
    
    public init(repository: LocalizationRepository) {
        self.repository = repository
    }
    
    public func loadPreferredLanguage(userId: UUID) async throws -> LocalizationEntity? {
        try await repository.loadPreferredLanguage(userId: userId)
    }
    
    public func savePreferredLanguage(userId: UUID, languageCode: String) async throws {
        let available = try await repository.fetchAvailableLocalizations()
        let label = available.first(where: { $0.languageCode == languageCode })?.languageLabel ?? languageCode
        let entity = LocalizationEntity(languageCode: languageCode, languageLabel: label)
        try await repository.savePreferredLanguage(entity, for: userId)
    }

    public func fetchLocalizationBundle() -> Bundle {
        repository.fetchLocalizationBundle()
    }
    
    public func fetchAvailableLocalizations() async throws -> [LocalizationEntity] {
        try await repository.fetchAvailableLocalizations()
    }
}
