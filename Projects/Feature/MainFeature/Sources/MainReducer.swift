import Rex
import MainFeatureInterface

public struct MainReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout MainState, action: MainAction) -> [Effect<MainAction>] {
        switch action {
        case .changeTab(let flow):
            state.flow = flow
        case .showMotion(let id):
            state.isShowingMotion = true
            state.motionAlarmId = id
        case .closeMotion(let id):
            // 해당 알람 ID와 일치할 때만 닫기
            if state.motionAlarmId == id {
                state.isShowingMotion = false
                state.motionAlarmId = nil
            }
        }
        return []
    }
}
