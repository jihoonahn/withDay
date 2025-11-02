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
            let metadata = context.attributes.metadata
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    AlarmIconView(isAlerting: metadata?.isAlerting ?? false)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let metadata = metadata {
                        if !metadata.isAlerting,
                           let nextAlarmTime = metadata.nextAlarmTime {
                            AlarmTimeView(nextAlarmTime: nextAlarmTime)
                        } else if metadata.isAlerting {
                            MotionProgressView(
                                motionCount: metadata.motionCount,
                                requiredCount: metadata.requiredMotionCount
                            )
                        }
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    if let metadata = metadata {
                        if metadata.isAlerting {
                            MotionCountdownView(
                                motionCount: metadata.motionCount,
                                requiredCount: metadata.requiredMotionCount
                            )
                        } else if let nextAlarmTime = metadata.nextAlarmTime {
                            TimeCountdownView(nextAlarmTime: nextAlarmTime)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let metadata = metadata {
                        if let label = metadata.alarmLabel, !label.isEmpty {
                            AlarmLabelView(label: label)
                        } else if metadata.isAlerting {
                            ShakeInstructionView()
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: (metadata?.isAlerting ?? false) ? "hand.raised.fill" : "alarm.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: (metadata?.isAlerting ?? false) ? [.red, .orange] : [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.title3)
            } compactTrailing: {
                if let metadata = metadata {
                    if metadata.isAlerting {
                        CompactMotionView(
                            motionCount: metadata.motionCount,
                            requiredCount: metadata.requiredMotionCount
                        )
                    } else if let nextAlarmTime = metadata.nextAlarmTime {
                        CompactTimeView(nextAlarmTime: nextAlarmTime)
                    }
                }
            } minimal: {
                Image(systemName: (metadata?.isAlerting ?? false) ? "hand.raised.fill" : "alarm.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: (metadata?.isAlerting ?? false) ? [.red, .orange] : [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.title3)
            }
        }
    }
}

// MARK: - Expanded Region Views

private struct AlarmIconView: View {
    let isAlerting: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: isAlerting ? "hand.raised.fill" : "alarm.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: isAlerting ? [.red, .orange] : [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(isAlerting ? "Shake" : "Alarm")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

private struct AlarmTimeView: View {
    let nextAlarmTime: Date
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(formatTime(nextAlarmTime))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Scheduled")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct MotionProgressView: View {
    let motionCount: Int
    let requiredCount: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(motionCount)/\(requiredCount)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Shakes")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct TimeCountdownView: View {
    let nextAlarmTime: Date
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Time Remaining")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(timeRemainingString(from: nextAlarmTime))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .contentTransition(.numericText())
        }
    }
}

private struct MotionCountdownView: View {
    let motionCount: Int
    let requiredCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Shakes Remaining")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            let remaining = max(0, requiredCount - motionCount)
            Text("\(remaining)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: remaining > 0 ? [.red, .orange] : [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .contentTransition(.numericText())
            
            if remaining > 0 {
                Text("more shake\(remaining == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("Complete!")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            }
        }
    }
}

private struct AlarmLabelView: View {
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.orange.opacity(0.15))
        )
    }
}

private struct ShakeInstructionView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.raised.fill")
                .font(.caption2)
                .foregroundColor(.red)
            
            Text("Shake to dismiss")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.red.opacity(0.15))
        )
    }
}

// MARK: - Compact Views

private struct CompactTimeView: View {
    let nextAlarmTime: Date
    
    var body: some View {
        Text(compactTimeRemaining(from: nextAlarmTime))
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .contentTransition(.numericText())
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
