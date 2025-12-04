import Rex
import RankFeatureInterface

public struct RankReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout RankState, action: RankAction) -> [Effect<RankAction>] {
        switch action {
        default:
            return []
        }
    }
}
