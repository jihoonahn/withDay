import SwiftUI
import AlarmCore
import ActivityKit

struct LockScreenView: View {
    let attributes: AlarmAttributes
    let state: AlarmAttributes.ContentState
    
    var body: some View {
        VStack(spacing: 16) {
            if state.isAlerting {
                VStack(spacing: 12) {
                    let remaining = max(0, state.requiredMotionCount - state.motionCount)
                    Text("\(remaining)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: remaining > 0 ? [.white, .gray] : [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText())
                    
                    if remaining > 0 {
                        Text("Shake\(remaining == 1 ? "" : "s") needed to dismiss")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Complete!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                    
                    if state.motionCount > 0 {
                        Text("\(state.motionCount)/\(state.requiredMotionCount) shakes detected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            } else {
                // Alarm is scheduled - show time remaining
                VStack(spacing: 12) {
                    Text(formatTime(attributes.scheduledTime))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(timeRemainingString(from: attributes.scheduledTime))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText())
                        .padding(.top, 4)
                        .monospacedDigit()
                }
                .padding()
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
