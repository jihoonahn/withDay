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
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 100 {
                        // 왼쪽으로 스와이프 - 이전 날짜
                        let calendar = Calendar.current
                        if let previousDay = calendar.date(byAdding: .day, value: -1, to: state.currentDisplayDate) {
                            interface.send(.setCurrentDisplayDate(previousDay))
                        }
                    } else if value.translation.width < -100 {
                        // 오른쪽으로 스와이프 - 다음 날짜
                        let calendar = Calendar.current
                        if let nextDay = calendar.date(byAdding: .day, value: 1, to: state.currentDisplayDate) {
                            interface.send(.setCurrentDisplayDate(nextDay))
                        }
                    }
                }
        )
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
        static let minItemSpacing: CGFloat = 80 // 아이템 간 최소 간격
        static let dividerHeight: CGFloat = 20 // 12시 구분선 높이
        static let headerTopPadding: CGFloat = 100 // 헤더 하단 여백
        static let basePeriodRatio: CGFloat = 0.4 // 각 구간의 기본 높이 비율
    }
    
    // MARK: - Current Day Timeline
    private func currentDayTimelineView(availableHeight: CGFloat) -> some View {
        let items = timelineItems(for: state.currentDisplayDate)
        let timelineData = calculateTimelineData(
            for: items,
            availableHeight: availableHeight
        )
        let itemPositions = calculateItemPositions(
            items: items,
            timelineData: timelineData
        )
        
        return ZStack(alignment: .topLeading) {
            timelineBackgroundLine(height: timelineData.totalHeight)
            timelinePeriodDividers(timelineData: timelineData)
            
            if items.isEmpty {
                emptyTimelineView
                    .frame(height: timelineData.totalHeight)
                    .padding(.top, TimelineConstants.headerTopPadding)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index < itemPositions.count && index >= 0 {
                        let position = itemPositions[index]
                        let safeY = position.y.isFinite ? position.y : 0
                        let safePixelsPerMinute = position.pixelsPerMinute.isFinite && position.pixelsPerMinute > 0 
                            ? position.pixelsPerMinute 
                            : 1.0
                        
                        timelineItemView(
                            item: item,
                            pixelsPerMinute: safePixelsPerMinute,
                            relatedMemos: relatedMemos(for: item)
                        )
                        .offset(y: safeY)
                    }
                }
            }
        }
        .frame(height: timelineData.totalHeight)
        .frame(maxWidth: .infinity)
        .padding(.top, TimelineConstants.headerTopPadding)
    }
    
    // MARK: - Item Position Calculation
    private struct ItemPosition {
        let y: CGFloat
        let pixelsPerMinute: CGFloat
    }
    
    private func calculateItemPositions(
        items: [TimelineItem],
        timelineData: TimelineData
    ) -> [ItemPosition] {
        guard timelineData.periodHeights.count >= 2,
              timelineData.periodPixelsPerMinute.count >= 2 else {
            return []
        }
        
        var positions: [ItemPosition] = []
        var lastEndY: CGFloat = -1000
        
        for item in items {
            let period = item.timeValue < 720 ? 0 : 1
            guard period >= 0 && period < timelineData.periodHeights.count else {
                continue
            }
            
            let periodOffset = period == 0 ? 0.0 : timelineData.periodHeights[0] + TimelineConstants.dividerHeight
            
            var pixelsPerMinute = timelineData.periodPixelsPerMinute[period]
            if !pixelsPerMinute.isFinite || pixelsPerMinute <= 0 {
                pixelsPerMinute = 1.0
            }
            
            let timeInPeriod = period == 0 ? item.timeValue : item.timeValue - 720
            let baseY = periodOffset + CGFloat(timeInPeriod) * pixelsPerMinute
            
            // 안전한 Y 위치 계산
            let safeBaseY = baseY.isFinite ? baseY : 0
            let safeLastEndY = lastEndY.isFinite ? lastEndY : -1000
            
            // 이전 아이템과 겹치지 않도록 위치 계산
            let finalY = max(safeBaseY, safeLastEndY + TimelineConstants.minItemSpacing)
            
            // 아이템 높이 계산
            let endTime = min(item.endTimeValue ?? item.timeValue, 1440)
            let duration = max(0, endTime - item.timeValue) // 음수 방지
            let timeHeight = CGFloat(duration) * pixelsPerMinute
            let itemHeight = max(100, timeHeight) // 최소 100, 시간 기반 높이
            
            // 마지막 끝 위치 업데이트
            let safeFinalY = finalY.isFinite ? finalY : 0
            let safeItemHeight = itemHeight.isFinite ? itemHeight : 100
            lastEndY = safeFinalY + safeItemHeight
            
            positions.append(ItemPosition(y: safeFinalY, pixelsPerMinute: pixelsPerMinute))
        }
        
        return positions
    }
    
    private func timelineBackgroundLine(height: CGFloat) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(JColor.textSecondary.opacity(0.2))
                .frame(width: 2, height: height)
                .frame(width: 50)
        }
    }
    
    private func timelinePeriodDividers(timelineData: TimelineData) -> some View {
        let morningHeight = timelineData.periodHeights.count > 0 
            ? timelineData.periodHeights[0] 
            : 0
        let afternoonHeight = timelineData.periodHeights.count > 1 
            ? timelineData.periodHeights[1] 
            : 0
        
        return VStack(spacing: 0) {
            // 오전 구간 (0-12시)
            Rectangle()
                .fill(Color.clear)
                .frame(height: morningHeight)
            
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
                .frame(height: afternoonHeight)
        }
    }
    
    // MARK: - Timeline Data Structure
    private struct TimelineData {
        let periodHeights: [CGFloat] // [오전 높이, 오후 높이]
        let periodPixelsPerMinute: [CGFloat] // [오전 픽셀/분, 오후 픽셀/분]
        let totalHeight: CGFloat
    }
    
    private func calculateTimelineData(
        for items: [TimelineItem],
        availableHeight: CGFloat
    ) -> TimelineData {
        // 안전한 높이 값 보장
        let safeAvailableHeight = max(availableHeight, 100)
        
        // 각 시간대(12시간)별 아이템들의 총 길이 및 개수 계산
        var morningTotalDuration: Int = 0
        var afternoonTotalDuration: Int = 0
        var morningItemCount: Int = 0
        var afternoonItemCount: Int = 0
        
        for item in items {
            var duration = item.endTimeValue.map { $0 - item.timeValue } 
                ?? TimelineConstants.defaultAlarmDuration
            
            // 자정을 넘어가는 일정 처리 (현재 날짜에서는 24:00까지)
            let actualEndTime = item.endTimeValue ?? item.timeValue
            let maxEndTime = min(actualEndTime, 1440) // 최대 24:00
            duration = maxEndTime - item.timeValue
            
            if item.timeValue < 720 {
                // 오전 구간
                if maxEndTime <= 720 {
                    // 오전에만 있는 경우
                    morningTotalDuration += duration
                    morningItemCount += 1
                } else {
                    // 오전부터 오후까지 이어지는 경우
                    let morningDuration = 720 - item.timeValue
                    let afternoonDuration = maxEndTime - 720
                    morningTotalDuration += morningDuration
                    afternoonTotalDuration += afternoonDuration
                    morningItemCount += 1
                    afternoonItemCount += 1
                }
            } else {
                // 오후 구간
                afternoonTotalDuration += duration
                afternoonItemCount += 1
            }
        }
        
        // 기본 높이: 각 구간이 12시간(720분)을 나타내는 최소 높이
        let basePeriodHeight = safeAvailableHeight * TimelineConstants.basePeriodRatio
        let minPeriodHeight = max(basePeriodHeight, 100) // 최소 높이 보장
        
        // 아이템이 포함된 구간의 높이 계산
        // 기본 720분 + 아이템들의 총 길이 + 아이템 간 간격 고려
        let minutesPerPeriod = 720
        let basePixelsPerMinute = basePeriodHeight / CGFloat(minutesPerPeriod)
        
        // 안전한 itemSpacingInMinutes 계산 (0으로 나누기 및 NaN/무한대 방지)
        let itemSpacingInMinutes: Int
        if basePixelsPerMinute > 0 && basePixelsPerMinute.isFinite {
            let spacingValue = TimelineConstants.minItemSpacing / basePixelsPerMinute
            if spacingValue.isFinite && spacingValue > 0 {
                itemSpacingInMinutes = Int(spacingValue)
            } else {
                itemSpacingInMinutes = 0
            }
        } else {
            itemSpacingInMinutes = 0
        }
        
        let morningTotalMinutes = max(
            minutesPerPeriod,
            minutesPerPeriod 
                + morningTotalDuration 
                + (morningItemCount > 0 ? (morningItemCount - 1) * itemSpacingInMinutes : 0)
        )
        let afternoonTotalMinutes = max(
            minutesPerPeriod,
            minutesPerPeriod 
                + afternoonTotalDuration 
                + (afternoonItemCount > 0 ? (afternoonItemCount - 1) * itemSpacingInMinutes : 0)
        )
        
        // 각 구간의 높이 계산 - 아이템이 많을수록 높이 증가
        let morningHeight = max(
            minPeriodHeight,
            CGFloat(morningTotalMinutes) * basePixelsPerMinute
        )
        let afternoonHeight = max(
            minPeriodHeight,
            CGFloat(afternoonTotalMinutes) * basePixelsPerMinute
        )
        
        // 각 구간의 픽셀/분 비율 (0으로 나누기 방지)
        let morningPixelsPerMinute = morningTotalMinutes > 0
            ? morningHeight / CGFloat(morningTotalMinutes)
            : basePixelsPerMinute
        let afternoonPixelsPerMinute = afternoonTotalMinutes > 0
            ? afternoonHeight / CGFloat(afternoonTotalMinutes)
            : basePixelsPerMinute
        
        // 전체 높이 계산 (마지막 아이템 이후 여백 포함)
        let bottomPadding: CGFloat = 100
        let totalHeight = morningHeight + afternoonHeight + TimelineConstants.dividerHeight + bottomPadding
        
        return TimelineData(
            periodHeights: [morningHeight, afternoonHeight],
            periodPixelsPerMinute: [morningPixelsPerMinute, afternoonPixelsPerMinute],
            totalHeight: max(totalHeight, safeAvailableHeight)
        )
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
    
    private func timelineItemView(item: TimelineItem, pixelsPerMinute: CGFloat, relatedMemos: [MemosEntity]) -> some View {
        // 안전한 픽셀/분 비율 계산 (NaN/무한대 방지)
        let safePixelsPerMinute = pixelsPerMinute.isFinite && pixelsPerMinute > 0 
            ? pixelsPerMinute 
            : 1.0
        
        return HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .frame(width: 15, height: 15)
                    .glassEffect()
                    .frame(width: 50)
                    .padding(.top, 4)
                
                // 알람 또는 스케줄인 경우 길이 표시
                if let endTimeValue = item.endTimeValue {
                    // 자정을 넘어가는 일정 처리 (현재 날짜에서는 24:00까지)
                    let actualEndTime = min(endTimeValue, 1440)
                    let duration = actualEndTime - item.timeValue
                    let height = max(CGFloat(duration) * safePixelsPerMinute, 40)
                    let safeHeight = height.isFinite ? height : 40
                    
                    let color: Color = {
                        switch item.type {
                        case .alarm:
                            return JColor.primary.opacity(0.3)
                        case .schedule:
                            return JColor.success.opacity(0.3)
                        }
                    }()
                    Rectangle()
                        .fill(color)
                        .frame(width: 2, height: safeHeight)
                        .frame(width: 50)
                } else {
                    Spacer()
                        .frame(height: 20)
                }
            }
            
            TimelineRow(item: item, relatedMemos: relatedMemos)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func relatedMemos(for item: TimelineItem) -> [MemosEntity] {
        switch item.type {
        case .alarm(let alarm):
            return state.allMemos.filter { $0.alarmId == alarm.id }
        case .schedule(let schedule):
            return state.allMemos.filter { $0.scheduleId == schedule.id }
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

private struct TimelineItem: Identifiable, Equatable {
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
