import Rex
import HomeFeatureInterface

public struct HomeReducer: Reducer {
    public init() {}

    public func reduce(state: inout HomeState, action: HomeAction) -> [Effect<HomeAction>] {
        return []
    }
}
