import Rex

public protocol HomeInterface {
    var stateStream: AsyncStream<HomeState> { get }
    func send(_ action: HomeAction)
    func getCurrentState() -> HomeState
}
