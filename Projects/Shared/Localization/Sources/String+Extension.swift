import Foundation

public extension String {
    func localized(
        table: String? = nil,
        locale: Locale? = nil
    ) -> String {
        Localization.localized(self, table: table, locale: locale)
    }
    
    func localizedArguments(with arguments: CVarArg...) -> String {
        String(format: Localization.localized(self), arguments: arguments)
    }
}
