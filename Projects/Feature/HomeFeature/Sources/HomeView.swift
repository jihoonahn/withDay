import Foundation
import SwiftUI
import RefineUIIcons
import Rex
import BaseFeature
import HomeFeatureInterface
import MemosFeatureInterface
import Designsystem
import Dependency
import Localization
import MemosDomainInterface
import AlarmsDomainInterface
import SchedulesDomainInterface
import Utility

public struct HomeView: View {
    let interface: HomeInterface
    @State private var state = HomeState()

    let memoFactory: MemoFactory

    public init(
        interface: HomeInterface,
    ) {
        self.interface = interface
        self.memoFactory = DIContainer.shared.resolve(MemoFactory.self)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: JColor.primary))
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            headerSection
                            
                            if timelineItems.isEmpty {
                                emptyTimelineView
                            } else {
                                timelineView
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            interface.send(.viewAppear)
        }
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}

// MARK: - TimelineItem
private enum TimelineItemType {
    case alarm(AlarmsEntity)
    case schedule(SchedulesEntity)
}

private struct TimelineItem: Identifiable {
    let id: UUID
    let type: TimelineItemType
    let time: String
    let timeValue: Int // 시간을 분 단위로 변환한 값 (정렬용)
}

// MARK: - Components
private extension HomeView {
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(state.homeTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(JColor.textPrimary)
                
                if let wakeDuration = state.wakeDurationDescription {
                    Text(wakeDuration)
                        .font(.system(size: 14))
                        .foregroundStyle(JColor.textSecondary)
                } else {
                    Text("HomeWakeDurationSubtitle".localized())
                        .font(.system(size: 14))
                        .foregroundStyle(JColor.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.bottom, 24)
    }
    
    var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []
        
        // 알람 추가
        for alarm in todayAlarms {
            let time = extractTime(from: alarm.time)
            let timeValue = timeToMinutes(time)
            items.append(TimelineItem(
                id: alarm.id,
                type: .alarm(alarm),
                time: time,
                timeValue: timeValue
            ))
        }
        
        // 스케줄 추가
        for schedule in todaySchedules {
            let timeValue = timeToMinutes(schedule.startTime)
            items.append(TimelineItem(
                id: schedule.id,
                type: .schedule(schedule),
                time: schedule.startTime,
                timeValue: timeValue
            ))
        }
        
        // 시간순으로 정렬
        return items.sorted { $0.timeValue < $1.timeValue }
    }
    
    var timelineView: some View {
        VStack(spacing: 0) {
            ForEach(Array(timelineItems.enumerated()), id: \.element.id) { index, item in
                TimelineRow(
                    item: item,
                    isFirst: index == 0,
                    isLast: index == timelineItems.count - 1
                )
            }
        }
    }
    
    var emptyTimelineView: some View {
        VStack(spacing: 16) {
            Image(refineUIIcon: .calendar32Regular)
                .foregroundColor(JColor.textSecondary)
                .font(.system(size: 48))
            
            Text("HomeTimelineEmptyTitle".localized())
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(JColor.textSecondary)
            
            Text("HomeTimelineEmptyDescription".localized())
                .font(.system(size: 14))
                .foregroundColor(JColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
    
    var todayAlarms: [AlarmsEntity] {
        let today = Date()
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: today) - 1 // 0: 일요일, 6: 토요일
        
        return state.alarms.filter { alarm in
            if alarm.repeatDays.isEmpty {
                return alarm.isEnabled
            } else {
                return alarm.isEnabled && alarm.repeatDays.contains(todayWeekday)
            }
        }
    }
    
    var todaySchedules: [SchedulesEntity] {
        let todayString = formatTodayDateString()
        return state.schedules.filter { schedule in
            schedule.date == todayString
        }.sorted { schedule1, schedule2 in
            schedule1.startTime < schedule2.startTime
        }
    }
    
    func formatTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    func extractTime(from timeString: String) -> String {
        if timeString.contains(" ") {
            let parts = timeString.split(separator: " ")
            return parts.count >= 2 ? String(parts[1]) : timeString
        }
        return timeString
    }
    
    func timeToMinutes(_ timeString: String) -> Int {
        let components = timeString.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return 0
        }
        return hour * 60 + minute
    }
}

// MARK: - TimelineRow
private struct TimelineRow: View {
    let item: TimelineItem
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line & time
            VStack(spacing: 0) {
                // Time label
                Text(formatTime(item.time))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(JColor.textSecondary)
                    .frame(width: 60, alignment: .trailing)
                    .padding(.top, 4)
                
                // Timeline dot & line
                ZStack(alignment: .top) {
                    // Vertical line
                    if !isLast {
                        Rectangle()
                            .fill(dotColor.opacity(0.3))
                            .frame(width: 2)
                            .padding(.top, 12)
                    }
                    
                    // Dot
                    Circle()
                        .fill(dotColor)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(JColor.background, lineWidth: 2)
                        )
                        .shadow(color: dotColor.opacity(0.5), radius: 4, x: 0, y: 2)
                }
                .frame(width: 60)
                
                Spacer()
            }
            
            // Content card
            contentCard
                .padding(.top, 4)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var contentCard: some View {
        switch item.type {
        case .alarm(let alarm):
            AlarmTimelineCard(alarm: alarm)
        case .schedule(let schedule):
            ScheduleTimelineCard(schedule: schedule)
        }
    }
    
    private var dotColor: Color {
        switch item.type {
        case .alarm:
            return JColor.primary
        case .schedule:
            return JColor.success
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString
        }
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - AlarmTimelineCard
private struct AlarmTimelineCard: View {
    let alarm: AlarmsEntity
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(refineUIIcon: .clockAlarm20Regular)
                .foregroundColor(JColor.primary)
                .font(.system(size: 20))
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(alarm.time))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(JColor.textPrimary)
                
                if let label = alarm.label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundColor(JColor.textSecondary)
                } else {
                    Text("HomeAlarmDefaultLabel".localized())
                        .font(.system(size: 14))
                        .foregroundColor(JColor.textSecondary.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(JColor.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(JColor.primary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: JColor.primary.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatTime(_ timeString: String) -> String {
        let cleanTime: String
        if timeString.contains(" ") {
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
}

// MARK: - ScheduleTimelineCard
private struct ScheduleTimelineCard: View {
    let schedule: SchedulesEntity
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(refineUIIcon: .calendar20Regular)
                .foregroundColor(JColor.success)
                .font(.system(size: 20))
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(JColor.textPrimary)
                
                HStack(spacing: 4) {
                    Text(formatTime(schedule.startTime))
                        .font(.system(size: 14))
                        .foregroundColor(JColor.textSecondary)
                    
                    if schedule.startTime != schedule.endTime {
                        Text("~")
                            .font(.system(size: 14))
                            .foregroundColor(JColor.textSecondary)
                        
                        Text(formatTime(schedule.endTime))
                            .font(.system(size: 14))
                            .foregroundColor(JColor.textSecondary)
                    }
                }
                
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(JColor.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(JColor.success.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: JColor.success.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatTime(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString
        }
        return String(format: "%02d:%02d", hour, minute)
    }
}
