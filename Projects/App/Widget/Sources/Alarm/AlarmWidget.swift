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
                
                DynamicIslandExpandedRegion(.trailing) {
                    Group {
                        if !contentState.isAlerting {
                            AlarmTimeView(nextAlarmTime: context.attributes.scheduledTime)
                        } else {
                            MotionProgressView(
                                motionCount: contentState.motionCount,
                                requiredCount: contentState.requiredMotionCount
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
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
                
                DynamicIslandExpandedRegion(.bottom) {
                    Group {
                        if contentState.isAlerting {
                            ShakeInstructionView()
                        } else if let label = context.attributes.alarmLabel, !label.isEmpty {
                            AlarmLabelView(label: label)
                        } else {
                            AlarmStatusView(nextAlarmTime: context.attributes.scheduledTime)
                        }
                    }
                    .frame(maxWidth: .infinity)
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
        HStack(alignment: .center, spacing: 8) {
            ZStack {
                Circle()
                    .fill(isAlerting ? Color.red.opacity(0.3) : Color.orange.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isAlerting ? "hand.raised.fill" : "alarm.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isAlerting ? .red : .orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("WithDay")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text(isAlerting ? "Alarming" : "Alarm")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12)
        .padding(.vertical, 8)
    }
}

private struct CompactLogoView: View {
    let isAlerting: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isAlerting ? [.red.opacity(0.3), .orange.opacity(0.3)] : [.orange.opacity(0.3), .red.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
            
            Image(systemName: isAlerting ? "hand.raised.fill" : "alarm.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: isAlerting ? [.red, .orange] : [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

private struct AlarmTimeView: View {
    let nextAlarmTime: Date
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(formatTime(nextAlarmTime))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Scheduled")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
    }
}

private struct MotionProgressView: View {
    let motionCount: Int
    let requiredCount: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(motionCount)/\(requiredCount)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Shakes")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
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

private struct AlarmStatusView: View {
    let nextAlarmTime: Date
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)
            
            Text("Alarm set for \(formatTime(nextAlarmTime))")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.3))
        )
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
            
            if remaining > 0 {
                Text("more shake\(remaining == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text("Complete!")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct AlarmLabelView: View {
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.3))
        )
    }
}

private struct ShakeInstructionView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 11))
                .foregroundColor(.red)
            
            Text("Shake to dismiss")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.red.opacity(0.3))
        )
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

private struct CompactMotionView: View {
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

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

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
