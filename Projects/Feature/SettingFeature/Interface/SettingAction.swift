import Rex
import UserDomainInterface
import SettingDomainInterface

public enum SettingAction: ActionType {
    case fetchUserInformation
    case setUserInformation(name: String, email: String)  // 통합 액션
    case nameTextDidChanged(String)
    case emailTextDidChanged(String)
    case deleteUserAccount
    case logout
}
