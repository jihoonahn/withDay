import ActivityKit
import AlarmScheduleCoreInterface
import AppIntents
import WidgetKit
import SwiftUI

struct AlarmWidget: Widget {
    var body: some WidgetConfiguration {
        return ActivityConfiguration(for: AlarmAttributes.self) { context in
            return LockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            let contentState = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LogoView(style: .basic)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.leading, 12)
                }

                DynamicIslandExpandedRegion(.center) {
                    Group {
                        if contentState.isAlerting {
                            WakeUpView(attributes: context.attributes)
                        } else {
                            TimeCountdownView(nextAlarmTime: context.attributes.scheduledTime)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } compactLeading: {
                LogoView(style: .compact)
            } compactTrailing: {
                if contentState.isAlerting {
                    CompactWakeUpView()
                } else {
                    CompactTimeView(nextAlarmTime: context.attributes.scheduledTime)
                }
            } minimal: {
                LogoView(style: .minimal)
            }
            .keylineTint(.white)
        }
    }
}
