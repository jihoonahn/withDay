import Rex

public enum MainAction: ActionType {
    case changeTab(to: MainState.Flow)
}
