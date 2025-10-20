import Rex
import HomeFeatureInterface

public struct HomeReducer: Reducer {
    public init() {}

    public func reduce(state: inout HomeState, action: HomeAction) -> [Effect<HomeAction>] {
        switch action {
        case .viewAppear:
            return []
        case let .showMemoSheet(status):
            state.sheetAction = status
            return []
        }
    }
}
