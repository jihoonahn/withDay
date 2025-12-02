import ActivityKit
import AlarmKit
import AlarmScheduleCoreInterface
import AppIntents
import WidgetKit
import SwiftUI

struct AlarmWidget: Widget {
    var body: some WidgetConfiguration {
        return ActivityConfiguration(for: AlarmAttributes<AlarmScheduleAttributes>.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LogoView(style: .basic)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.leading, 12)
                }

                DynamicIslandExpandedRegion(.center) {
                    Group {
                        if let metadata = context.attributes.metadata, metadata.isAlerting {
                            WakeUpView(attributes: context.attributes)
                        } else if let metadata = context.attributes.metadata {
                            TimeCountdownView(nextAlarmTime: metadata.nextAlarmTime)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } compactLeading: {
                LogoView(style: .compact)
            } compactTrailing: {
                if let metadata = context.attributes.metadata {
                    if metadata.isAlerting {
                        CompactWakeUpView()
                    } else {
                        CompactTimeView(nextAlarmTime: metadata.nextAlarmTime)
                    }
                }
            } minimal: {
                LogoView(style: .minimal)
            }
            .keylineTint(.white)
        }
    }
}
