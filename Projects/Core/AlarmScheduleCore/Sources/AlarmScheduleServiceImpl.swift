import Foundation
import SwiftUI
import AlarmKit
import AlarmScheduleCoreInterface
import AlarmScheduleDomainInterface
import Utility
import AppIntents

// MARK: - AlarmScheduleServiceImpl

public final class AlarmScheduleServiceImpl: AlarmScheduleService {

    // MARK: - Properties
    private let alarmManager = AlarmManager.shared
    private let calendar = Calendar.current
    private var cachedEntities: [UUID: AlarmScheduleEntity] = [:]
    private var cachedAlarms: [UUID: Alarm] = [:]
    private var cachedSchedules: [UUID: Alarm.Schedule] = [:]

    public init() {}
    // MARK: - Public Methods

    public func scheduleAlarm(_ alarm: AlarmScheduleDomainInterface.AlarmScheduleEntity) async throws {
        // 권한 확인
        guard await checkAuthorization() else {
            throw AlarmServiceError.notificationAuthorizationDenied
        }

        // 캐시 엔티티 저장 (toggle/update에서 사용)
        cachedEntities[alarm.id] = alarm
        
        // 시간 파싱
        let comps = alarm.time.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else {
            throw AlarmServiceError.invalidTimeFormat
        }
        let hour = comps[0], minute = comps[1]
        
        // AlarmKit Schedule 생성
        let schedule: Alarm.Schedule
        if alarm.repeatDays.isEmpty {
            // 일회성 알람: 오늘의 알람 시간 계산
            var todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            todayComponents.hour = hour
            todayComponents.minute = minute
            todayComponents.second = 0
            
            guard let todayAlarmDate = Calendar.current.date(from: todayComponents) else {
                throw AlarmServiceError.dateCreationFailed
            }
            
            // 오늘 알람 시간이 이미 지났으면 내일로 설정, 아니면 오늘로 설정
            let alarmDate = todayAlarmDate > Date.now ? todayAlarmDate : Calendar.current.date(byAdding: .day, value: 1, to: todayAlarmDate) ?? todayAlarmDate
            
            schedule = .fixed(alarmDate)
        } else {
            // 반복 알람: repeatDays를 Locale.Weekday로 변환
            // repeatDays는 0-6 형식 (0=일, 1=월, ..., 6=토)
            let weekdays = alarm.repeatDays.compactMap { day -> Locale.Weekday? in
                let calendarWeekday = day + 1  // 0->1(일), 1->2(월), ..., 6->7(토)
                
                // Weekday enum을 사용하여 변환
                if let weekday = Weekday(rawValue: calendarWeekday) {
                    return weekday.localeWeekday
                }
                return nil
            }
            
            guard !weekdays.isEmpty else {
                throw AlarmServiceError.invalidTimeFormat
            }
            
            let relTime = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
            let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
            schedule = .relative(.init(time: relTime, repeats: recurrence))
        }
        
        // 다음 알람 시간 계산 (Widget에서 사용)
        let calculatedNextAlarmTime: Date
        if let nextTime = calculateNextAlarmTime(from: alarm) {
            calculatedNextAlarmTime = nextTime
        } else {
            // 계산 실패 시 현재 시간 사용 (fallback)
            calculatedNextAlarmTime = Date()
        }
        
        // AlarmPresentation 생성
        let alarmLabel = LocalizedStringResource(stringLiteral: alarm.label ?? "Alarm")

        // stopButton을 제거하여 사용자가 쉽게 알람을 해제하지 못하도록 함
        // 모션 감지 등 미션 완료 후에만 해제 가능하도록 함
        let alert = AlarmPresentation.Alert(
            title: alarmLabel
            // stopButton과 secondaryButton을 제거하여 버튼을 통한 해제 방지
        )

        let presentation = AlarmPresentation(alert: alert)
        
        let metadata = AlarmScheduleAttributes(
            alarmId: alarm.id,
            alarmLabel: alarm.label,
            nextAlarmTime: calculatedNextAlarmTime,
            isAlerting: true,
            lastUpdateTime: Date()
        )
        
        // AlarmAttributes 생성
        let attributes = AlarmAttributes<AlarmScheduleAttributes>(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color.accentColor
        )
        
        // AppIntent 생성
        // stopIntent를 제거하여 버튼을 통한 해제 방지
        // 대신 모션 감지가 완료된 후에만 알람이 해제되도록 함
        let secondaryIntent = OpenAlarmAppIntent(alarmID: alarm.id.uuidString)

        // AlarmConfiguration 생성
        // stopIntent를 제거하여 사용자가 쉽게 알람을 해제하지 못하도록 함
        let configuration = AlarmManager.AlarmConfiguration<AlarmScheduleAttributes>(
            schedule: schedule,
            attributes: attributes,
            secondaryIntent: secondaryIntent
        )
        
        // AlarmKit에 스케줄 등록
        do {
            _ = try await alarmManager.schedule(id: alarm.id, configuration: configuration)
        } catch {
            print("❌ [AlarmScheduleService] 알람 스케줄링 실패: \(alarm.id) - \(error)")
            // 실제 에러를 다시 throw하여 상세 정보 전달
            throw error
        }
        
        // 캐시 업데이트
        cachedSchedules[alarm.id] = schedule
        
        do {
            let registeredAlarms = try alarmManager.alarms
            if let registeredAlarm = registeredAlarms.first(where: { $0.id == alarm.id }) {
                cachedAlarms[alarm.id] = registeredAlarm
            } else {
                print("⚠️ [AlarmKit] 경고: 알람이 등록되지 않음!")
            }
        } catch {
            print("⚠️ [AlarmKit] 알람 목록 조회 실패: \(error)")
        }
    }
    
    public func cancelAlarm(_ alarmId: UUID) async throws {
        try alarmManager.cancel(id: alarmId)
        cachedEntities.removeValue(forKey: alarmId)
        cachedSchedules.removeValue(forKey: alarmId)
        cachedAlarms.removeValue(forKey: alarmId)
    }
    
    public func updateAlarm(_ alarm: AlarmScheduleDomainInterface.AlarmScheduleEntity) async throws {
        try await cancelAlarm(alarm.id)
        try await scheduleAlarm(alarm)
    }
    
    public func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws {
        if isEnabled {
            guard var entity = cachedEntities[alarmId] else {
                throw NSError(domain: "AlarmService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Entity not found; load from DB first"])
            }
            // 캐시된 엔티티의 isEnabled 상태를 업데이트
            // struct이므로 새 인스턴스 생성이 필요하지만, var로 선언되어 있으므로 직접 수정 가능
            entity.isEnabled = true
            // 캐시 업데이트
            cachedEntities[alarmId] = entity
            try await scheduleAlarm(entity)
        } else {
            try await cancelAlarm(alarmId)
        }
    }

    public func stopAlarm(_ alarmId: UUID) async throws {
        try alarmManager.stop(id: alarmId)
    }

    public func getAlarmStatus(alarmId: UUID) async throws -> AlarmScheduleCoreInterface.AlarmStatus? {
        let alarms = try alarmManager.alarms
        guard let alarm = alarms.first(where: { $0.id == alarmId }) else {
            return nil
        }
        switch alarm.state {
        case .scheduled:
            return .scheduled
        case .countdown:
            return .scheduled
        case .paused:
            return .paused
        case .alerting:
            return .alerting
        @unknown default:
            return .unknown
        }
    }
    
    // MARK: - Private Methods
    
    private func checkAuthorization() async -> Bool {
        switch alarmManager.authorizationState {
        case .notDetermined:
            do {
                let status = try await alarmManager.requestAuthorization()
                return status == .authorized
            } catch {
                return false
            }
        case .authorized:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
    
    /// 알람 엔티티로부터 다음 알람 시간 계산
    private func calculateNextAlarmTime(from alarm: AlarmScheduleEntity) -> Date? {
        // 시간 파싱
        let comps = alarm.time.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else {
            return nil
        }
        let hour = comps[0], minute = comps[1]
        
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // 오늘 해당 시간
        guard let todayAlarmTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) else {
            return nil
        }
        
        // 반복 알람인 경우
        if !alarm.repeatDays.isEmpty {
            // 오늘 요일 확인 (Calendar는 1=일요일, 7=토요일)
            let todayWeekday = calendar.component(.weekday, from: now)
            // 0-6 형식으로 변환 (0=일요일, 6=토요일)
            let todayWeekdayIndex = todayWeekday - 1
            
            // 오늘 알람 시간이 지났는지 확인
            if todayAlarmTime > now {
                // 오늘이 반복 요일에 포함되어 있는지 확인
                if alarm.repeatDays.contains(todayWeekdayIndex) {
                    return todayAlarmTime
                }
            }
            
            // 다음 반복 요일 찾기
            var daysToAdd = 1
            var nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: today)!
            
            // 최대 7일까지 확인
            for _ in 0..<7 {
                let weekday = calendar.component(.weekday, from: nextDate)
                let weekdayIndex = weekday - 1  // 0-6 형식으로 변환
                
                if alarm.repeatDays.contains(weekdayIndex) {
                    guard let nextAlarmTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: nextDate) else {
                        continue
                    }
                    return nextAlarmTime
                }
                daysToAdd += 1
                nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: today)!
            }
            
            // 다음 주 첫 번째 반복 요일
            if let firstRepeatDay = alarm.repeatDays.sorted().first {
                // firstRepeatDay는 0-6 형식, todayWeekdayIndex도 0-6 형식
                let daysUntilFirst = (firstRepeatDay - todayWeekdayIndex + 7) % 7
                let targetDate = calendar.date(byAdding: .day, value: daysUntilFirst == 0 ? 7 : daysUntilFirst, to: today)!
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate)
            }
        } else {
            // 일회성 알람
            if todayAlarmTime > now {
                return todayAlarmTime
            } else {
                // 오늘 시간이 지났으면 내일
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow)
            }
        }
        
        return nil
    }
    
    // MARK: - Public Sync Methods
    
    /// Supabase에서 알람 목록을 가져와서 AlarmKit에 동기화
    /// - Parameter alarms: 동기화할 알람 엔티티 목록
    public func syncAlarms(_ alarms: [AlarmScheduleEntity]) async throws {
        // 권한 확인
        guard await checkAuthorization() else {
            throw AlarmServiceError.notificationAuthorizationDenied
        }
        
        // 기존 캐시된 알람 중 동기화 목록에 없는 알람 취소
        let syncAlarmIds = Set(alarms.map { $0.id })
        let cachedAlarmIds = Set(cachedEntities.keys)
        let alarmsToCancel = cachedAlarmIds.subtracting(syncAlarmIds)
        
        for alarmId in alarmsToCancel {
            try await cancelAlarm(alarmId)
        }
        
        // 활성화된 알람만 스케줄링
        let enabledAlarms = alarms.filter { $0.isEnabled }
        
        for alarm in enabledAlarms {
            do {
                try await scheduleAlarm(alarm)
            } catch {
                // 개별 알람 스케줄링 실패는 로그만 남기고 계속 진행
                print("⚠️ [AlarmScheduleService] 알람 스케줄링 실패: \(alarm.id) - \(error)")
            }
        }
    }
}
