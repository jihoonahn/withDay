import Rex
import SplashFeatureInterface

public struct SplashReducer: Reducer {
    public init() {}

    public func reduce(state: inout SplashState, action: SplashAction) -> [Effect<SplashAction>] {
        return []
    }
}
