import Rex

public enum SettingAction: ActionType {
    case nameTextDidChanged(String)
    case emailTextDidChanged(String)
    case logout
}
