import SwiftUI
import AlarmDomainInterface
import Designsystem
import RefineUIIcons

struct AlarmCard: View {
    let alarm: AlarmEntity
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 시간 표시
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(alarm.time))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(alarm.isEnabled ? JColor.textPrimary : JColor.textSecondary)
                
                if let label = alarm.label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(alarm.isEnabled ? JColor.textSecondary : JColor.textTertiary)
                }
                
                if !alarm.repeatDays.isEmpty {
                    Text(formatRepeatDays(alarm.repeatDays))
                        .font(.system(size: 12))
                        .foregroundColor(alarm.isEnabled ? JColor.textSecondary : JColor.textTertiary)
                }
            }
            
            Spacer()
            
            // 토글 스위치
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(JColor.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(JColor.cardBackground)
                .shadow(color: JColor.shadow.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .contextMenu {
            Button(role: .destructive, action: {
                showingDeleteAlert = true
            }) {
                Label("삭제", systemImage: "trash")
            }
        }
        .alert("알람 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("이 알람을 삭제하시겠습니까?")
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString
        }
        
        return String(format: "%02d:%02d", hour, minute)
    }
    
    private func formatRepeatDays(_ days: [Int]) -> String {
        if days.count == 7 {
            return "매일"
        }
        
        let dayNames = ["월", "화", "수", "목", "금", "토", "일"]
        let sortedDays = days.sorted()
        
        // 평일인지 확인 (월-금)
        if sortedDays == [1, 2, 3, 4, 5] {
            return "평일"
        }
        
        // 주말인지 확인
        if sortedDays == [0, 6] {
            return "주말"
        }
        
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }
}

