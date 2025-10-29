import SwiftUI
import AlarmDomainInterface
import Designsystem
import RefineUIIcons

struct AlarmCard: View {
    let alarm: AlarmEntity
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(alarm.time))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(alarm.isEnabled ? JColor.textPrimary : JColor.textSecondary)
                
                if let label = alarm.label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(alarm.isEnabled ? JColor.textSecondary : JColor.textDisabled)
                }
                
                if !alarm.repeatDays.isEmpty {
                    Text(formatRepeatDays(alarm.repeatDays))
                        .font(.system(size: 12))
                        .foregroundColor(alarm.isEnabled ? JColor.textSecondary : JColor.textDisabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
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
                .fill(JColor.card)
                .shadow(color: JColor.background.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatTime(_ timeString: String) -> String {
        // "yyyy-MM-dd HH:mm" 형식 또는 "HH:mm" 형식 처리
        let cleanTime: String
        if timeString.contains(" ") {
            // "2025-10-26 22:12" → "22:12" 추출
            let parts = timeString.split(separator: " ")
            cleanTime = parts.count >= 2 ? String(parts[1]) : timeString
        } else {
            cleanTime = timeString
        }
        
        let components = cleanTime.split(separator: ":")
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
        
        if sortedDays == [1, 2, 3, 4, 5] {
            return "평일"
        }
        
        if sortedDays == [0, 6] {
            return "주말"
        }
        
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }
}

