import Rex

public enum RankAction: ActionType {
    case loadRank
    case setLoading(Bool)
    case setError(String?)
    case clearError
}
