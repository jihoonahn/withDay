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
import Combine

public struct HomeView: View {
    let interface: HomeInterface
    @State private var state = HomeState()
    @State private var lastRefreshTime: Date = Date()

    public init(interface: HomeInterface) {
        self.interface = interface
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                JColor.background.ignoresSafeArea()
                
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: JColor.primary))
                } else {
                    ZStack(alignment: .top) {
                        ScrollView {
                            ZStack(alignment: .topLeading) {
                                timelineBackgroundLine
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 0) {
                                    if timelineItems.isEmpty {
                                        emptyTimelineView
                                    } else {
                                        timelineContentView
                                    }
                                    
                                    if state.isLoadingNextDay {
                                        loadingNextDayView
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 100)
                            }
                        }
                        headerView
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                            .background(
                                ZStack {
                                    Color(.systemBackground).opacity(0.8)
                                }
                                .blur(radius: 30)
                            )
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
    
    // MARK: - Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formatDateTitle(state.currentDisplayDate))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(JColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Timeline Background
    private var timelineBackgroundLine: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(JColor.textSecondary.opacity(0.2))
                .frame(width: 2)
                .frame(width: 50)
        }
    }
    
    // MARK: - Timeline Content
    private var timelineItems: [TimelineItem] {
        let alarms = state.currentAlarms.map {
            TimelineItem(
                id: $0.id,
                type: .alarm($0),
                time: extractTime(from: $0.time),
                timeValue: timeToMinutes(extractTime(from: $0.time))
            )
        }
        let schedules = state.currentSchedules.map {
            TimelineItem(
                id: $0.id,
                type: .schedule($0),
                time: $0.startTime,
                timeValue: timeToMinutes($0.startTime)
            )
        }
        return (alarms + schedules).sorted { $0.timeValue < $1.timeValue }
    }
    
    private var timelineContentView: some View {
        VStack(spacing: 0) {
            ForEach(Array(timelineItems.enumerated()), id: \.element.id) { index, item in
                TimelineRow(item: item, relatedMemos: relatedMemos(for: item))
            }
        }
    }
    
    private func relatedMemos(for item: TimelineItem) -> [MemosEntity] {
        switch item.type {
        case .alarm(let alarm):
            return state.allMemos.filter { $0.alarmId == alarm.id }
        case .schedule(let schedule):
            return state.allMemos.filter { $0.scheduleId == schedule.id }
        }
    }
    
    // MARK: - Empty State
    private var emptyTimelineView: some View {
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
    
    private var loadingNextDayView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: JColor.primary))
            .padding(.vertical, 20)
    }
    
    // MARK: - Date Formatting
    private func formatDateTitle(_ date: Date) -> String {
        return date.toString()
    }
    
    // MARK: - Time Formatting
    private func extractTime(from timeString: String) -> String {
        timeString.split(separator: " ").last.map(String.init) ?? timeString
    }
    
    private func timeToMinutes(_ timeString: String) -> Int {
        let components = timeString.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return 0 }
        return hour * 60 + minute
    }
    
    private func formatTime(_ timeString: String) -> String {
        let cleanTime = extractTime(from: timeString)
        let components = cleanTime.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return timeString }
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - TimelineRow
private struct TimelineRow: View {
    let item: TimelineItem
    let relatedMemos: [MemosEntity]
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            timelineIndicator
            contentCard
        }
        .padding(.vertical, 4)
    }
    
    private var timelineIndicator: some View {
        VStack(spacing: 0) {
            Circle()
                .frame(width: 15, height: 15)
                .glassEffect()
                .frame(width: 50)
                .padding(.top, 25)
        }
    }
    
    private var contentCard: some View {
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

    private func formatTime(_ timeString: String) -> String {
        let cleanTime = timeString.split(separator: " ").last.map(String.init) ?? timeString
        let components = cleanTime.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return timeString }
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - AlarmContentCard
private struct AlarmContentCard: View {
    let alarm: AlarmsEntity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(refineUIIcon: .clockAlarm20Regular)
                .foregroundColor(JColor.textPrimary)
                .font(.system(size: 20))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(alarm.time))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(JColor.textPrimary)
                
                Text(alarm.label?.isEmpty == false ? alarm.label! : "HomeAlarmDefaultLabel".localized())
                    .font(.system(size: 14))
                    .foregroundColor(alarm.label?.isEmpty == false ? JColor.textSecondary : JColor.textSecondary.opacity(0.6))
            }
            Spacer()
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        let cleanTime = timeString.split(separator: " ").last.map(String.init) ?? timeString
        let components = cleanTime.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return timeString }
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - ScheduleContentCard
private struct ScheduleContentCard: View {
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
                    Text(formatTime(schedule.startTime))
                    if schedule.startTime != schedule.endTime {
                        Text("~")
                        Text(formatTime(schedule.endTime))
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
    
    private func formatTime(_ timeString: String) -> String {
        let cleanTime = timeString.split(separator: " ").last.map(String.init) ?? timeString
        let components = cleanTime.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return timeString }
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - MemoCard
private struct MemoCard: View {
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

// MARK: - TimelineItem
private enum TimelineItemType {
    case alarm(AlarmsEntity)
    case schedule(SchedulesEntity)
}

private struct TimelineItem: Identifiable {
    let id: UUID
    let type: TimelineItemType
    let time: String
    let timeValue: Int
}
