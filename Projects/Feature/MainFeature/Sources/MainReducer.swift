import Rex
import MainFeatureInterface
import BaseFeature
import Utility

public struct MainReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout MainState, action: MainAction) -> [Effect<MainAction>] {
        switch action {
        case .showSheetFlow(let flow):
            state.sheetFlow = flow
            return []
        case let .showMotion(id, executionId):
            state.isShowingMotion = true
            state.motionAlarmId = id
            state.motionExecutionId = executionId
            return []
        case .closeMotion(let id):
            state.isShowingMotion = false
            state.motionAlarmId = nil
            state.motionExecutionId = nil
            return []
        }
    }
}
