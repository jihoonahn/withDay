import Rex

public protocol MemoInterface {
    var stateStream: AsyncStream<MemoState> { get }
    func send(_ action: MemoAction)
    func getCurrentState() -> MemoState
}
