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
                        VStack(spacing: 20) {
                            headerSection
                            
                            if !todayAlarms.isEmpty || !todaySchedules.isEmpty {
                                todayOverviewSection
                            }
                            
                            if !todayAlarms.isEmpty {
                                todayAlarmsSection
                            }
                            
                            if !todaySchedules.isEmpty {
                                todaySchedulesSection
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
    }
    
    var todayOverviewSection: some View {
        HStack(spacing: 12) {
            if !todayAlarms.isEmpty {
                overviewCard(
                    icon: RefineUIIcons.clock24Regular,
                    title: "HomeTodayAlarmsCount".localizedArguments(with: todayAlarms.count),
                    color: JColor.primary
                )
            }
            
            if !todaySchedules.isEmpty {
                overviewCard(
                    icon: RefineUIIcons.calendar24Regular,
                    title: "HomeTodaySchedulesCount".localizedArguments(with: todaySchedules.count),
                    color: JColor.success
                )
            }
        }
    }
    
    func overviewCard(icon: RefineUIIcons, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(refineUIIcon: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(JColor.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(JColor.card)
                .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    var todayAlarmsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HomeTodayAlarms".localized())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(JColor.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(todayAlarms.prefix(3), id: \.id) { alarm in
                    HomeAlarmRow(alarm: alarm)
                }
                
                if todayAlarms.count > 3 {
                    Text("HomeMoreAlarmsCount".localizedArguments(with: todayAlarms.count - 3))
                        .font(.system(size: 12))
                        .foregroundStyle(JColor.textSecondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(JColor.card)
                .shadow(color: JColor.background.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
    
    var todaySchedulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HomeTodaySchedules".localized())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(JColor.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(todaySchedules.prefix(3), id: \.id) { schedule in
                    HomeScheduleRow(schedule: schedule)
                }
                
                if todaySchedules.count > 3 {
                    Text("HomeMoreSchedulesCount".localizedArguments(with: todaySchedules.count - 3))
                        .font(.system(size: 12))
                        .foregroundStyle(JColor.textSecondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(JColor.card)
                .shadow(color: JColor.background.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
    
    var todayAlarms: [AlarmsEntity] {
        let today = Date()
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: today) - 1 // 0: 일요일, 6: 토요일
        
        return state.alarms.filter { alarm in
            if alarm.repeatDays.isEmpty {
                // 반복 없는 알람은 시간만 확인 (날짜는 알 수 없으므로 활성화된 것만 표시)
                return alarm.isEnabled
            } else {
                // 반복 알람은 오늘 요일이 포함되어 있고 활성화되어 있는지 확인
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
}

// MARK: - HomeAlarmRow
private struct HomeAlarmRow: View {
    let alarm: AlarmsEntity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(refineUIIcon: .clockAlarm16Regular)
                .foregroundColor(JColor.primary)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(alarm.time))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JColor.textPrimary)
                
                if let label = alarm.label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundStyle(JColor.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(JColor.background)
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

// MARK: - HomeScheduleRow
private struct HomeScheduleRow: View {
    let schedule: SchedulesEntity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(refineUIIcon: .calendar16Regular)
                .foregroundColor(JColor.success)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JColor.textPrimary)
                
                HStack(spacing: 4) {
                    Text(formatTime(schedule.startTime))
                        .font(.system(size: 12))
                        .foregroundStyle(JColor.textSecondary)
                    
                    if schedule.startTime != schedule.endTime {
                        Text("~")
                            .font(.system(size: 12))
                            .foregroundStyle(JColor.textSecondary)
                        
                        Text(formatTime(schedule.endTime))
                            .font(.system(size: 12))
                            .foregroundStyle(JColor.textSecondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(JColor.background)
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

