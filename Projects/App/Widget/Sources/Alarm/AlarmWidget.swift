import ActivityKit
import AlarmCore
import AlarmKit
import AppIntents
import WidgetKit
import SwiftUI

struct AlarmWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<AlarmData>.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                }
                DynamicIslandExpandedRegion(.trailing) {
                }
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        Image(systemName: "heart.fill").tint(.red)
                        Text("진행률")
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    
                }
            } compactLeading: {
                
            } compactTrailing: {
                
            } minimal: {
                
            }
        }
    }
}
