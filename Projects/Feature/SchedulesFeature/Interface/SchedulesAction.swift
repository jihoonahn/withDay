import Rex

public enum SchedulesAction: ActionType {
    case loadRank
    case setLoading(Bool)
    case setError(String?)
    case clearError
}
