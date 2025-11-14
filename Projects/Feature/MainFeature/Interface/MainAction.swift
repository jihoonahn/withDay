import Foundation
import Rex

public enum MainAction: ActionType {
    case changeTab(to: MainState.Flow)
    case showMotion(id: UUID)
    case closeMotion(id: UUID)
}
