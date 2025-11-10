import Foundation
import Rex
import RefineUIIcons
import LocalizationDomainInterface

public struct SettingState: StateType {
    public var name: String = ""
    public var email: String = ""
    public var version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.1"
    public var languages: [LocalizationEntity] = []
    public var languageCode: String = ""
    public var notificationEnabled: Bool = true
    public var toastMessage: String = ""
    public var toastIsPresented: Bool = false
    
    public init() {}
}

public extension SettingState {
    var languageDisplayName: String {
        guard let selected = languages.first(where: { $0.languageCode == languageCode }) else {
            return languageCode.isEmpty ? "" : languageCode
        }
        return selected.languageLabel
    }
}
