import Foundation
import LocalizationDomainInterface
import LocalizationCoreInterface

public final class LocalizationRepositoryImpl: LocalizationRepository {
    private let service: LocalizationService
    
    public init(service: LocalizationService) {
        self.service = service
    }
    
    public func loadPreferredLanguage(userId: UUID) async throws -> LocalizationEntity? {
        guard let languageCode = try await service.loadLanguage() else {
            return nil
        }
        let map = service.availableLocalizations()
        let label = map[languageCode] ?? languageCode
        return LocalizationEntity(languageCode: languageCode, languageLabel: label)
    }
    
    public func savePreferredLanguage(_ entity: LocalizationEntity, for userId: UUID) async throws {
        try await service.saveLanguage(entity.languageCode)
    }

    public func fetchLocalizationBundle() -> Bundle {
        service.fetchbundle()
    }
    
    public func fetchAvailableLocalizations() async throws -> [LocalizationEntity] {
        let map = service.availableLocalizations()
        return map.map { LocalizationEntity(languageCode: $0.key, languageLabel: $0.value) }
            .sorted { $0.languageLabel < $1.languageLabel }
    }
}
