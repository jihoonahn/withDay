import SwiftUI
import AlarmKit
import AlarmCore

struct LockScreenView: View {
    let attributes: AlarmAttributes<AlarmData>
    let state: AlarmPresentationState
    
    var body: some View {
        VStack(spacing: 16) {
            if let metadata = attributes.metadata {
                if metadata.isAlerting {
                    // Alarm is currently alerting - show shake count
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Shake to dismiss")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        let remaining = max(0, metadata.requiredMotionCount - metadata.motionCount)
                        Text("\(remaining)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: remaining > 0 ? [.red, .orange] : [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .contentTransition(.numericText())
                        
                        if remaining > 0 {
                            Text("more shake\(remaining == 1 ? "" : "s") needed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Complete!")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                        
                        if metadata.motionCount > 0 {
                            Text("\(metadata.motionCount)/\(metadata.requiredMotionCount) shakes detected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                } else if let nextAlarmTime = metadata.nextAlarmTime {
                    // Alarm is scheduled - show time remaining
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "alarm.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            if let label = metadata.alarmLabel, !label.isEmpty {
                                Text(label)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Alarm")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Text(formatTime(nextAlarmTime))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(timeRemainingString(from: nextAlarmTime))
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .contentTransition(.numericText())
                            .padding(.top, 4)
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
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
}
