import Foundation
import Rex

public enum MainAction: ActionType {
    case showSheetFlow(MainState.SheetFlow?)
    case showMotion(id: UUID, executionId: UUID?)
    case closeMotion(id: UUID)
}
