import Rex

public protocol MotionInterface {
    var stateStream: AsyncStream<MotionState> { get }
    func send(_ action: MotionAction)
    func getCurrentState() -> MotionState
}
