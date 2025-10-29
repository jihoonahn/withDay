import Rex
import UserDomainInterface

public enum LoginAction: ActionType {
    case selectToAppleOauth
    case selectToGoogleOauth
    case toggleLoading(Bool)
    case loginSuccess
    case loginFailure
}
