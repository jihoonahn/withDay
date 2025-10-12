import Rex
import MainFeatureInterface

public struct MainReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout MainState, action: MainAction) -> [Effect<MainAction>] {
        return []
    }
}
