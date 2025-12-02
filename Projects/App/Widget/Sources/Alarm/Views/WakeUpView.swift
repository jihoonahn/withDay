import SwiftUI
import RefineUIIcons
import AlarmKit
import AlarmScheduleCoreInterface

struct WakeUpView: View {
    let attributes: AlarmAttributes<AlarmScheduleAttributes>

    var body: some View {
        VStack(spacing: 4) {
            Text("Wake Up")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)
            
            if let metadata = attributes.metadata {
                if let label = metadata.alarmLabel {
                    Text(label)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                } else {
                    Text(String().formatTime(metadata.nextAlarmTime))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

