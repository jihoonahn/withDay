import SwiftUI

struct TimeCountdownView: View {
    let nextAlarmTime: Date
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Time Remaining")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)
            
            // 실시간 카운트다운 - 시스템이 자동으로 업데이트
            Text(timerInterval: Date()...nextAlarmTime, countsDown: true)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
