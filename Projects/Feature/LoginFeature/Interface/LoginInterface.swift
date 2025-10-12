import Rex

public protocol LoginInterface {
    var stateStream: AsyncStream<LoginState> { get }
    func send(_ action: LoginAction)
    func getCurrentState() -> LoginState
}
