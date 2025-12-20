import Foundation
import AlarmsDomainInterface
import SchedulesDomainInterface
import MemosDomainInterface
import Utility

// MARK: - Timeline Helper
struct TimelineHelper {
    
    // MARK: - Constants
    enum Constants {
        static let defaultAlarmDuration: Int = 30 // 알람 기본 지속 시간 (분)
    }
    
    // MARK: - Timeline Items
    static func createTimelineItems(
        for date: Date,
        alarms: [AlarmsEntity],
        schedules: [SchedulesEntity]
    ) -> [TimelineItem] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        var items: [TimelineItem] = []
        
        // 알람 추가
        let weekday = calendar.component(.weekday, from: date) - 1
        let dayAlarms = alarms.filter { alarm in
            alarm.isEnabled && (alarm.repeatDays.isEmpty || alarm.repeatDays.contains(weekday))
        }
        
        for alarm in dayAlarms {
            let timeValue = alarm.time.timeToMinutes()
            items.append(TimelineItem(
                id: alarm.id,
                type: .alarm(alarm),
                time: alarm.time.extractTime(),
                timeValue: timeValue,
                endTimeValue: timeValue + Constants.defaultAlarmDuration
            ))
        }
        
        // 스케줄 추가
        let daySchedules = schedules.filter { schedule in
            let normalizedScheduleDate = schedule.date.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: " ").first ?? schedule.date
                .components(separatedBy: "T").first ?? schedule.date
            return normalizedScheduleDate == dateString
        }
        
        for schedule in daySchedules {
            let startTimeValue = schedule.startTime.timeToMinutes()
            var endTimeValue = schedule.endTime.timeToMinutes()
            
            // 자정을 넘어가는 일정 처리 (endTime < startTime인 경우)
            if endTimeValue < startTimeValue {
                endTimeValue = 1440 // 24:00까지
            }
            
            // 현재 날짜 범위 내에 있는 일정만 추가
            if startTimeValue < 1440 {
                items.append(TimelineItem(
                    id: schedule.id,
                    type: .schedule(schedule),
                    time: schedule.startTime,
                    timeValue: startTimeValue,
                    endTimeValue: min(endTimeValue, 1440)
                ))
            }
        }
        
        return items.sorted { $0.timeValue < $1.timeValue }
    }
    
    // MARK: - Related Memos
    static func relatedMemos(
        for item: TimelineItem,
        allMemos: [MemosEntity]
    ) -> [MemosEntity] {
        guard !allMemos.isEmpty else {
            return []
        }
        
        switch item.type {
        case .alarm(let alarm):
            return allMemos.compactMap { memo in
                guard let alarmId = memo.alarmId, alarmId == alarm.id else {
                    return nil
                }
                return memo
            }
        case .schedule(let schedule):
            return allMemos.compactMap { memo in
                guard let scheduleId = memo.scheduleId, scheduleId == schedule.id else {
                    return nil
                }
                return memo
            }
        }
    }
}
