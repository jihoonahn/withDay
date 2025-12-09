import SwiftUI
import Rex

public protocol SchedulesFactory {
    func makeInterface() -> SchedulesInterface
    func makeView() -> AnyView
}
