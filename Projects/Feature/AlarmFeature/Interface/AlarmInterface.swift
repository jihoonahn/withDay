import Foundation
import Rex

public protocol AlarmInterface {
    var stateStream: AsyncStream<AlarmState> { get }
    func send(_ action: AlarmAction)
    func getCurrentState() -> AlarmState
}
