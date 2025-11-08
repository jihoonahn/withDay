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
        return LocalizationEntity(languageCode: languageCode)
    }
    
    public func savePreferredLanguage(_ entity: LocalizationEntity, for userId: UUID) async throws {
        try await service.saveLanguage(entity.languageCode)
    }
}

