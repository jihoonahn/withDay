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
                    GeometryReader { geometry in
                        ZStack(alignment: .top) {
                            ScrollView {
                                currentDayTimelineView(availableHeight: geometry.size.height)
                                    .padding(.horizontal, 20)
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
        HStack(spacing: 16) {
            // 이전 날짜 버튼
            Button(action: {
                let calendar = Calendar.current
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: state.currentDisplayDate) {
                    interface.send(.setCurrentDisplayDate(previousDay))
                }
            }) {
                Image(refineUIIcon: .chevronLeft24Regular)
                    .foregroundColor(JColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .glassEffect(.clear.interactive(), in: .circle)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(formatDateTitle(state.currentDisplayDate))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(JColor.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 다음 날짜 버튼
            Button(action: {
                let calendar = Calendar.current
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: state.currentDisplayDate) {
                    interface.send(.setCurrentDisplayDate(nextDay))
                }
            }) {
                Image(refineUIIcon: .chevronRight24Regular)
                    .foregroundColor(JColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .glassEffect(.clear.interactive(), in: .circle)
            }
        }
    }
    
    // MARK: - Constants
    private enum TimelineConstants {
        static let defaultAlarmDuration: Int = 30 // 알람 기본 지속 시간 (분)
        static let dividerHeight: CGFloat = 20 // 12시 구분선 높이
        static let headerTopPadding: CGFloat = 100 // 헤더 하단 여백
    }
    
    // MARK: - Current Day Timeline
    private func currentDayTimelineView(availableHeight: CGFloat) -> some View {
        let items = timelineItems(for: state.currentDisplayDate)
        // 각 아이템의 메모 개수 계산 (중복 키 방지)
        var memoCountsDict: [UUID: Int] = [:]
        for item in items {
            memoCountsDict[item.id] = relatedMemos(for: item).count
        }
        let memoCounts = memoCountsDict
        let timelineData = TimelineCalculator.calculateTimelineData(
            for: items,
            memoCounts: memoCounts
        )
        let itemPositions = TimelineCalculator.calculateItemPositions(
            items: items,
            timelineData: timelineData,
            memoCounts: memoCounts
        )
        
        return ZStack(alignment: .topLeading) {
            timelineBackgroundLine(height: timelineData.totalHeight)
            timelinePeriodDividers(timelineData: timelineData)
            
            if items.isEmpty {
                emptyTimelineView
                    .frame(height: timelineData.totalHeight)
                    .padding(.top, TimelineConstants.headerTopPadding)
            } else {
                // items와 itemPositions의 길이가 일치하는지 확인
                if items.count == itemPositions.count && !items.isEmpty {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index < itemPositions.count {
                            let position = itemPositions[index]
                            let safeY = position.y.isFinite ? position.y : 0
                            
                            timelineItemView(
                                item: item,
                                relatedMemos: relatedMemos(for: item)
                            )
                            .offset(y: safeY)
                        }
                    }
                }
            }
        }
        .frame(height: timelineData.totalHeight)
        .frame(maxWidth: .infinity)
        .padding(.top, TimelineConstants.headerTopPadding)
    }
    
    
    private func timelineBackgroundLine(height: CGFloat) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(JColor.textSecondary.opacity(0.2))
                .frame(width: 2, height: height)
                .frame(width: 50)
        }
    }
    
    private func timelinePeriodDividers(timelineData: TimelineCalculator.TimelineData) -> some View {
        return VStack(spacing: 0) {
            // 오전 구간 (0-12시)
            Rectangle()
                .fill(Color.clear)
                .frame(height: timelineData.morningHeight)
            
            // 12시 구분선
            HStack(spacing: 8) {
                Rectangle()
                    .fill(JColor.textSecondary.opacity(0.5))
                    .frame(width: 2, height: 1)
                    .frame(width: 50)
                
                Text("12:00")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(JColor.textSecondary.opacity(0.7))
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            // 오후 구간 (12-24시)
            Rectangle()
                .fill(Color.clear)
                .frame(height: timelineData.afternoonHeight)
        }
    }
    
    
    // MARK: - Timeline Items
    private func timelineItems(for date: Date) -> [TimelineItem] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        var items: [TimelineItem] = []
        
        // 알람 추가
        let weekday = calendar.component(.weekday, from: date) - 1
        let dayAlarms = state.alarms.filter { alarm in
            alarm.isEnabled && (alarm.repeatDays.isEmpty || alarm.repeatDays.contains(weekday))
        }
        
        for alarm in dayAlarms {
            let timeValue = timeToMinutes(extractTime(from: alarm.time))
            items.append(TimelineItem(
                id: alarm.id,
                type: .alarm(alarm),
                time: extractTime(from: alarm.time),
                timeValue: timeValue,
                endTimeValue: timeValue + TimelineConstants.defaultAlarmDuration
            ))
        }
        
        // 스케줄 추가
        let daySchedules = state.schedules.filter { schedule in
            let normalizedScheduleDate = schedule.date.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: " ").first ?? schedule.date
                .components(separatedBy: "T").first ?? schedule.date
            return normalizedScheduleDate == dateString
        }
        
        for schedule in daySchedules {
            let startTimeValue = timeToMinutes(schedule.startTime)
            var endTimeValue = timeToMinutes(schedule.endTime)
            
            // 자정을 넘어가는 일정 처리 (endTime < startTime인 경우)
            // 현재 날짜에서는 시작 시간부터 24:00(1440분)까지 표시
            if endTimeValue < startTimeValue {
                // 다음 날까지 이어지는 일정: 현재 날짜에서는 24:00까지
                endTimeValue = 1440
            }
            
            // 현재 날짜 범위 내에 있는 일정만 추가
            if startTimeValue < 1440 {
                items.append(TimelineItem(
                    id: schedule.id,
                    type: .schedule(schedule),
                    time: schedule.startTime,
                    timeValue: startTimeValue,
                    endTimeValue: min(endTimeValue, 1440) // 최대 24:00까지
                ))
            }
        }
        
        return items.sorted { $0.timeValue < $1.timeValue }
    }
    
    private func timelineItemView(item: TimelineItem, relatedMemos: [MemosEntity]) -> some View {
        return HStack(alignment: .top, spacing: 16) {
            timelineIndicatorView(for: item)
            
            TimelineRow(item: item, relatedMemos: relatedMemos)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Timeline Indicator
    private func timelineIndicatorView(for item: TimelineItem) -> some View {
        VStack(spacing: 0) {
            // 타임라인 노드 (원형 마커)
            Circle()
                .frame(width: 15, height: 15)
                .glassEffect()
                .frame(width: 50)
                .padding(.top, 4)
            
            // 아이템 지속 시간을 나타내는 세로선
            if let endTimeValue = item.endTimeValue {
                timelineDurationLine(
                    startTime: item.timeValue,
                    endTime: min(endTimeValue, 1440)
                )
            } else {
                // endTime이 없는 경우 기본 높이
                Spacer()
                    .frame(height: 20)
            }
        }
    }
    
    private func timelineDurationLine(startTime: Int, endTime: Int) -> some View {
        let duration = max(0, endTime - startTime)
        let height = CGFloat(duration) * TimelineCalculator.Constants.pixelsPerMinute
        let safeHeight = max(40, height.isFinite ? height : 40)
        
        return Rectangle()
            .fill(JColor.primary.opacity(0.3))
            .frame(width: 2, height: safeHeight)
            .frame(width: 50)
    }
    
    private func relatedMemos(for item: TimelineItem) -> [MemosEntity] {
        // 안전한 메모 필터링
        guard !state.allMemos.isEmpty else {
            return []
        }
        
        switch item.type {
        case .alarm(let alarm):
            return state.allMemos.compactMap { memo in
                guard let alarmId = memo.alarmId, alarmId == alarm.id else {
                    return nil
                }
                return memo
            }
        case .schedule(let schedule):
            return state.allMemos.compactMap { memo in
                guard let scheduleId = memo.scheduleId, scheduleId == schedule.id else {
                    return nil
                }
                return memo
            }
        }
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
        let cleanTime = extractTime(from: timeString)
        let components = cleanTime.split(separator: ":")
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
        .frame(maxWidth: .infinity)
    }
}

// MARK: - TimelineRow
private struct TimelineRow: View {
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
private enum TimelineItemType: Equatable {
    case alarm(AlarmsEntity)
    case schedule(SchedulesEntity)
    
    static func == (lhs: TimelineItemType, rhs: TimelineItemType) -> Bool {
        switch (lhs, rhs) {
        case (.alarm(let lhsAlarm), .alarm(let rhsAlarm)):
            return lhsAlarm.id == rhsAlarm.id
        case (.schedule(let lhsSchedule), .schedule(let rhsSchedule)):
            return lhsSchedule.id == rhsSchedule.id
        default:
            return false
        }
    }
}

private struct TimelineItem: Identifiable, Equatable, TimelineItemProtocol {
    let id: UUID
    let type: TimelineItemType
    let time: String
    let timeValue: Int
    var endTimeValue: Int?
    
    init(id: UUID, type: TimelineItemType, time: String, timeValue: Int, endTimeValue: Int? = nil) {
        self.id = id
        self.type = type
        self.time = time
        self.timeValue = timeValue
        self.endTimeValue = endTimeValue
    }
    
    static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        return lhs.id == rhs.id && 
               lhs.type == rhs.type && 
               lhs.time == rhs.time && 
               lhs.timeValue == rhs.timeValue &&
               lhs.endTimeValue == rhs.endTimeValue
    }
}
