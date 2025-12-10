import Foundation
import SwiftUI
import AlarmKit
import AlarmSchedulesCoreInterface
import AlarmsDomainInterface
import Utility
import AppIntents

// MARK: - AlarmScheduleServiceImpl

public final class AlarmSchedulesServiceImpl: AlarmSchedulesService {

    // MARK: - Properties
    private let alarmManager = AlarmManager.shared
    private let calendar = Calendar.current
    private var cachedEntities: [UUID: AlarmsEntity] = [:]
    private var cachedAlarms: [UUID: Alarm] = [:]
    private var cachedSchedules: [UUID: Alarm.Schedule] = [:]

    public init() {}
    // MARK: - Public Methods

    public func scheduleAlarm(_ alarm: AlarmsEntity) async throws {
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
        
        let schedule: Alarm.Schedule
        if alarm.repeatDays.isEmpty {
            let now = Date()
            let today = calendar.startOfDay(for: now)
            
            guard let todayAlarmTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) else {
                throw AlarmServiceError.dateCreationFailed
            }
            
            let alarmDate: Date
            if todayAlarmTime > now {
                alarmDate = todayAlarmTime
            } else {
                // 오늘 시간이 지났으면 내일
                guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
                    throw AlarmServiceError.dateCreationFailed
                }
                guard let tomorrowAlarmTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow) else {
                    throw AlarmServiceError.dateCreationFailed
                }
                alarmDate = tomorrowAlarmTime
            }
            
            print("📅 [AlarmScheduleService] 일회성 알람 날짜 계산: \(alarm.id), \(alarmDate)")
            schedule = .fixed(alarmDate)
        } else {
            let weekdays = alarm.repeatDays.compactMap { day -> Locale.Weekday? in
                let calendarWeekday = day + 1  // 0->1(일), 1->2(월), ..., 6->7(토)
                
                // Weekday enum을 사용하여 변환
                if let weekday = Weekday(rawValue: calendarWeekday) {
                    return weekday.localeWeekday
                } else {
                    print("⚠️ [AlarmScheduleService] 요일 변환 실패: day=\(day), calendarWeekday=\(calendarWeekday)")
                    return nil
                }
            }
            
            guard !weekdays.isEmpty else {
                print("❌ [AlarmScheduleService] 유효한 요일이 없음: repeatDays=\(alarm.repeatDays)")
                throw AlarmServiceError.invalidTimeFormat
            }
            
            print("📅 [AlarmScheduleService] 반복 알람 요일 변환: repeatDays=\(alarm.repeatDays) -> weekdays=\(weekdays)")
            
            let relTime = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
            let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
            schedule = .relative(.init(time: relTime, repeats: recurrence))
        }
        
        // 다음 알람 시간 계산 (Widget에서 사용)
        guard let calculatedNextAlarmTime = calculateNextAlarmTime(from: alarm) else {
            print("❌ [AlarmScheduleService] 다음 알람 시간 계산 실패: \(alarm.id)")
            throw AlarmServiceError.dateCalculationFailed
        }

        // 계산된 시간이 미래 시간인지 확인
        let now = Date()
        guard calculatedNextAlarmTime > now else {
            print("❌ [AlarmScheduleService] 계산된 알람 시간이 과거입니다: \(alarm.id), 계산된 시간: \(calculatedNextAlarmTime), 현재 시간: \(now)")
            throw AlarmServiceError.dateCalculationFailed
        }
        
        print("✅ [AlarmScheduleService] 다음 알람 시간 계산 성공: \(alarm.id), 시간: \(calculatedNextAlarmTime)")

        // AlarmPresentation 생성
        let alarmLabel = LocalizedStringResource(stringLiteral: alarm.label ?? "Alarm")
        let alert = AlarmPresentation.Alert(title: alarmLabel)
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
            tintColor: Color.white
        )
        
        let stopIntent = StopAlarmIntent(alarmID: alarm.id.uuidString)
        let secondaryIntent = OpenAlarmAppIntent(alarmID: alarm.id.uuidString)

        let configuration = AlarmManager.AlarmConfiguration<AlarmScheduleAttributes>(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: secondaryIntent
        )

        do {
            let alarms = try alarmManager.alarms
            if alarms.contains(where: { $0.id == alarm.id }) {
                print("⚠️ [AlarmScheduleService] 기존 알람 발견, 취소 후 재등록: \(alarm.id)")
                do {
                    try alarmManager.cancel(id: alarm.id)
                } catch {
                    // 취소 실패는 무시 (이미 취소되었거나 다른 상태일 수 있음)
                    print("⚠️ [AlarmScheduleService] 기존 알람 취소 실패 (무시하고 계속 진행): \(alarm.id) - \(error)")
                }
            }
        } catch {
            print("⚠️ [AlarmScheduleService] 기존 알람 확인 실패 (무시하고 계속 진행): \(error)")
        }
        
        // AlarmKit에 스케줄 등록
        do {
            print("🔔 [AlarmScheduleService] AlarmKit에 알람 등록 시도: \(alarm.id), schedule=\(schedule)")
            _ = try await alarmManager.schedule(id: alarm.id, configuration: configuration)
            print("✅ [AlarmScheduleService] AlarmKit에 알람 등록 성공: \(alarm.id)")
        } catch {
            print("❌ [AlarmScheduleService] 알람 스케줄링 실패: \(alarm.id) - \(error)")
            print("   - schedule: \(schedule)")
            print("   - hour: \(hour), minute: \(minute)")
            print("   - repeatDays: \(alarm.repeatDays)")
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
        // 알람이 존재하는지 먼저 확인
        do {
            let alarms = try alarmManager.alarms
            if alarms.contains(where: { $0.id == alarmId }) {
                try alarmManager.cancel(id: alarmId)
            } else {
                print("⚠️ [AlarmScheduleService] 알람이 이미 존재하지 않음: \(alarmId)")
            }
        } catch {
            // 알람 목록 조회 실패 시에도 취소 시도
            print("⚠️ [AlarmScheduleService] 알람 목록 조회 실패, 취소 시도: \(error)")
            do {
                try alarmManager.cancel(id: alarmId)
            } catch {
                // 취소 실패는 무시 (이미 취소되었거나 존재하지 않을 수 있음)
                print("⚠️ [AlarmScheduleService] 알람 취소 실패 (무시됨): \(alarmId) - \(error)")
            }
        }
        
        // 캐시는 항상 정리
        cachedEntities.removeValue(forKey: alarmId)
        cachedSchedules.removeValue(forKey: alarmId)
        cachedAlarms.removeValue(forKey: alarmId)
    }
    
    public func updateAlarm(_ alarm: AlarmsEntity) async throws {
        do {
            try await cancelAlarm(alarm.id)
        } catch {
            print("⚠️ [AlarmScheduleService] 알람 취소 실패 (무시하고 계속 진행): \(alarm.id) - \(error)")
        }
        try await scheduleAlarm(alarm)
    }
    
    public func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws {
        if isEnabled {
            guard var entity = cachedEntities[alarmId] else {
                throw AlarmServiceError.entityNotFound
            }
            entity.isEnabled = true
            cachedEntities[alarmId] = entity
            try await scheduleAlarm(entity)
        } else {
            try await cancelAlarm(alarmId)
        }
    }

    public func stopAlarm(_ alarmId: UUID) async throws {
        try alarmManager.stop(id: alarmId)
    }

    public func getAlarmStatus(alarmId: UUID) async throws -> AlarmSchedulesCoreInterface.AlarmStatus? {
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
    private func calculateNextAlarmTime(from alarm: AlarmsEntity) -> Date? {
        // 시간 파싱
        let comps = alarm.time.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else {
            print("⚠️ [AlarmScheduleService] 시간 파싱 실패: \(alarm.time)")
            return nil
        }
        let hour = comps[0], minute = comps[1]
        
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // 오늘 해당 시간
        guard let todayAlarmTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) else {
            print("⚠️ [AlarmScheduleService] 오늘 알람 시간 생성 실패: hour=\(hour), minute=\(minute)")
            return nil
        }
        
        // 반복 알람인 경우
        if !alarm.repeatDays.isEmpty {
            // 오늘 요일 확인 (Calendar는 1=일요일, 7=토요일)
            let todayWeekday = calendar.component(.weekday, from: now)
            // 0-6 형식으로 변환 (0=일요일, 6=토요일)
            let todayWeekdayIndex = todayWeekday - 1
            
            // 오늘 알람 시간이 아직 안 지났고, 오늘이 반복 요일에 포함되어 있으면 오늘 반환
            if todayAlarmTime > now && alarm.repeatDays.contains(todayWeekdayIndex) {
                return todayAlarmTime
            }
            
            // 다음 반복 요일 찾기 (오늘부터 최대 14일까지 확인하여 다음 주까지 포함)
            for daysToAdd in 1...14 {
                guard let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) else {
                    continue
                }
                
                let weekday = calendar.component(.weekday, from: nextDate)
                let weekdayIndex = weekday - 1  // 0-6 형식으로 변환
                
                if alarm.repeatDays.contains(weekdayIndex) {
                    guard let nextAlarmTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: nextDate) else {
                        continue
                    }
                    print("📅 [AlarmScheduleService] 다음 반복 알람 시간 찾음: \(alarm.id), \(daysToAdd)일 후, \(nextAlarmTime)")
                    return nextAlarmTime
                }
            }
            
            // 14일 안에 반복 요일을 찾지 못한 경우 (이론적으로는 발생하지 않아야 함)
            print("⚠️ [AlarmScheduleService] 다음 반복 요일을 찾지 못함: \(alarm.id), repeatDays: \(alarm.repeatDays)")
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
    public func syncAlarms(_ alarms: [AlarmsEntity]) async throws {
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
                print("⚠️ [AlarmScheduleService] 알람 스케줄링 실패: \(alarm.id) - \(error)")
            }
        }
    }
}
