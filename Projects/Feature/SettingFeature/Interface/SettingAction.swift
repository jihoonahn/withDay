import Rex
import UserDomainInterface

public enum SettingAction: ActionType {
    case fetchUserInformation
    case setUserInformation(name: String, email: String)
    case nameTextDidChanged(String)
    case emailTextDidChanged(String)
    case saveProfile(String)
    case deleteUserAccount
    case showToast(String)
    case toastStatus(Bool)
    case logout
    
    // Language Settings
    case loadLanguage
    case setLanguage(String)
    case saveLanguage(String)
    
    // Notification Settings
    case loadNotificationSetting
    case setNotificationSetting(Bool)
    case saveNotificationSetting(Bool)
}
