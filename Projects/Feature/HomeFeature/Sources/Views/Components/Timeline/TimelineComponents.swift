import SwiftUI
import RefineUIIcons
import Designsystem
import MemosDomainInterface
import AlarmsDomainInterface
import SchedulesDomainInterface
import Localization
import Utility

// MARK: - TimelineRow
struct TimelineRow: View {
    let item: TimelineItem
    let relatedMemos: [MemosEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            itemContent
            
            if !relatedMemos.isEmpty {
                memoSection
            }
        }
        .padding(16)
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var itemContent: some View {
        switch item.type {
        case .alarm(let alarm):
            AlarmContentCard(alarm: alarm)
        case .schedule(let schedule):
            ScheduleContentCard(schedule: schedule)
        }
    }
    
    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(relatedMemos, id: \.id) { memo in
                MemoCard(memo: memo)
            }
        }
    }
}

// MARK: - AlarmContentCard
struct AlarmContentCard: View {
    let alarm: AlarmsEntity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(refineUIIcon: .clockAlarm20Regular)
                .foregroundColor(JColor.textPrimary)
                .font(.system(size: 20))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.time.formatTime())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(JColor.textPrimary)
                
                Text(alarm.label?.isEmpty == false ? alarm.label! : "HomeAlarmDefaultLabel".localized())
                    .font(.system(size: 14))
                    .foregroundColor(alarm.label?.isEmpty == false ? JColor.textSecondary : JColor.textSecondary.opacity(0.6))
            }
            Spacer()
        }
    }
}

// MARK: - ScheduleContentCard
struct ScheduleContentCard: View {
    let schedule: SchedulesEntity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(refineUIIcon: .calendar20Regular)
                .foregroundColor(JColor.success)
                .font(.system(size: 20))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(JColor.textPrimary)
                
                HStack(spacing: 4) {
                    Text(schedule.startTime.formatTime())
                    if schedule.startTime != schedule.endTime {
                        Text("~")
                        Text(schedule.endTime.formatTime())
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(JColor.textSecondary)
                
                if !schedule.description.isEmpty {
                    Text(schedule.description)
                        .font(.system(size: 13))
                        .foregroundColor(JColor.textSecondary.opacity(0.8))
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            Spacer()
        }
    }
}

// MARK: - MemoCard
struct MemoCard: View {
    let memo: MemosEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .foregroundColor(JColor.warning)
                    .font(.system(size: 14))
                Text(memo.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(JColor.textPrimary)
                Spacer()
            }
            if !memo.description.isEmpty {
                Text(memo.description)
                    .font(.system(size: 13))
                    .foregroundColor(JColor.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .shadow(color: JColor.warning.opacity(0.2), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(JColor.warning.opacity(0.3), lineWidth: 1))
    }
}
