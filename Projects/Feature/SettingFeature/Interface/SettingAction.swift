import Rex

public enum SettingAction: ActionType {
    case loadUser
    case updateUser(User)
    case toggleDarkMode
    case openNotificationSettings
    case openLocationSettings
    case editProfile
    case changePassword
    case changeEmail
    case openPrivacyPolicy
    case openTermsOfService
    case contactSupport
    case logout
    case setLoading(Bool)
    case setError(String?)
    case clearError
}
