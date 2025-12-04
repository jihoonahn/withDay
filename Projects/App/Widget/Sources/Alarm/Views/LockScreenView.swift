import SwiftUI
import AlarmKit
import AlarmScheduleCoreInterface
import ActivityKit

struct LockScreenView: View {
    let attributes: AlarmAttributes<AlarmScheduleAttributes>
    let state: AlarmPresentationState
    
    var body: some View {
        VStack(spacing: 16) {
            if let metadata = attributes.metadata {
                if metadata.isAlerting {
                    VStack(spacing: 12) {
                        Text("Wake Up")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if let label = metadata.alarmLabel {
                            Text(label)
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                } else {
                    // Alarm is scheduled - show time remaining with real-time countdown
                    VStack(spacing: 12) {
                        // 알람 시간 표시
                        Text(metadata.nextAlarmTime, style: .time)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // 실시간 카운트다운 타이머
                        // nextAlarmTime이 미래 시간인지 확인하여 렌더링 에러 방지
                        if metadata.nextAlarmTime > Date() {
                            Text(timerInterval: Date()...metadata.nextAlarmTime, countsDown: true)
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
                        } else {
                            // 과거 시간인 경우 fallback 표시
                            Text("--:--:--")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                                .monospacedDigit()
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}
