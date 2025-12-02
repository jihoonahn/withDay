import WidgetKit
import SwiftUI
import ActivityKit
import AlarmKit
import AlarmScheduleCoreInterface
import AppIntents

@main
struct WithDayWidget: WidgetBundle {
    var body: some Widget {
        AlarmWidget()
    }
}
