import SwiftUI
import AlarmScheduleCore

struct MotionCountdownView: View {
    let attributes: AlarmAttributes
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Wake Up")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)
            
            if let label = attributes.alarmLabel {
                Text(label)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            } else {
                Text("🔔")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

