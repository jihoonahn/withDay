import Foundation
import Rex

public protocol SchedulesInterface {
    var stateStream: AsyncStream<SchedulesState> { get }
    func send(_ action: SchedulesAction)
    func getCurrentState() -> SchedulesState
}
