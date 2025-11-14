import SwiftUI
import AlarmScheduleCoreInterface
import ActivityKit

struct LockScreenView: View {
    let attributes: AlarmAttributes
    let state: AlarmAttributes.ContentState
    
    var body: some View {
        VStack(spacing: 16) {
            if state.isAlerting {
                VStack(spacing: 12) {
                    Text("Wake Up")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if let label = attributes.alarmLabel {
                        Text(label)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            } else {
                // Alarm is scheduled - show time remaining
                VStack(spacing: 12) {
                    Text(String().formatTime(attributes.scheduledTime))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(String().timeRemainingString(from: attributes.scheduledTime))
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
}
