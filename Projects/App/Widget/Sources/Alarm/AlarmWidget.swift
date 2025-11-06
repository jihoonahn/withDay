import ActivityKit
import AlarmCore
import AppIntents
import WidgetKit
import SwiftUI

struct AlarmWidget: Widget {
    var body: some WidgetConfiguration {
        return ActivityConfiguration(for: AlarmAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            let contentState = context.state
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    AppLogoView(isAlerting: contentState.isAlerting)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }

                DynamicIslandExpandedRegion(.center) {
                    Group {
                        if contentState.isAlerting {
                            MotionCountdownView(
                                motionCount: contentState.motionCount,
                                requiredCount: contentState.requiredMotionCount
                            )
                        } else {
                            TimeCountdownView(nextAlarmTime: context.attributes.scheduledTime)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } compactLeading: {
                CompactLogoView(isAlerting: contentState.isAlerting)
            } compactTrailing: {
                if contentState.isAlerting {
                    CompactMotionView(
                        motionCount: contentState.motionCount,
                        requiredCount: contentState.requiredMotionCount
                    )
                } else {
                    CompactTimeView(nextAlarmTime: context.attributes.scheduledTime)
                }
            } minimal: {
                CompactLogoView(isAlerting: contentState.isAlerting)
            }
            .keylineTint(.orange)
        }
    }
}

// MARK: - Expanded Region Views

private struct AppLogoView: View {
    let isAlerting: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            VStack {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12)
    }
}

private struct CompactLogoView: View {
    let isAlerting: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TimeCountdownView: View {
    let nextAlarmTime: Date
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Time Remaining")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)
            
            Text(timeRemainingString(from: nextAlarmTime))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct MotionCountdownView: View {
    let motionCount: Int
    let requiredCount: Int
    
    var body: some View {
        let remaining = max(0, requiredCount - motionCount)
        
        return VStack(spacing: 4) {
            Text("Shakes Remaining")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)
            
            Text("\(remaining)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Compact Views

private struct CompactTimeView: View {
    let nextAlarmTime: Date
    
    var body: some View {
        Text(compactTimeRemaining(from: nextAlarmTime))
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .contentTransition(.numericText())
            .shadow(color: .orange.opacity(0.3), radius: 1, x: 0, y: 1)
    }
}

struct CompactMotionView: View {
    let motionCount: Int
    let requiredCount: Int
    
    var body: some View {
        let remaining = max(0, requiredCount - motionCount)
        Text("\(remaining)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: remaining > 0 ? [.red, .orange] : [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .contentTransition(.numericText())
    }
}

// MARK: - Helper Functions

private func timeRemainingString(from date: Date) -> String {
    let now = Date()
    let timeInterval = date.timeIntervalSince(now)
    
    if timeInterval <= 0 {
        return "NOW"
    }
    
    let totalSeconds = Int(timeInterval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    
    if hours > 0 {
        return String(format: "%dh %02dm", hours, minutes)
    } else if minutes > 0 {
        return String(format: "%dm %02ds", minutes, seconds)
    } else {
        return String(format: "%ds", seconds)
    }
}

private func compactTimeRemaining(from date: Date) -> String {
    let now = Date()
    let timeInterval = date.timeIntervalSince(now)
    
    if timeInterval <= 0 {
        return "NOW"
    }
    
    let totalSeconds = Int(timeInterval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    
    if hours > 0 {
        return String(format: "%dh", hours)
    } else if minutes > 0 {
        return String(format: "%dm", minutes)
    } else {
        return String(format: "%ds", totalSeconds)
    }
}
