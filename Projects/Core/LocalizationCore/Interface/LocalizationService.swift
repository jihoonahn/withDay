import Foundation

public protocol LocalizationService {
    func saveLanguage(_ languageCode: String) async throws
    func loadLanguage() async throws -> String?
}
