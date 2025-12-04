import SwiftUI

struct CompactTimeView: View {
    let nextAlarmTime: Date
    
    var body: some View {
        Text(timerInterval: Date()...nextAlarmTime, countsDown: true)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .contentTransition(.numericText())
            .shadow(color: .orange.opacity(0.3), radius: 1, x: 0, y: 1)
            .monospacedDigit()
            .frame(minWidth: 40)
    }
}
