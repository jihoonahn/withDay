import Foundation
import Rex
import MemosDomainInterface
import AlarmsDomainInterface
import SchedulesDomainInterface

public enum HomeAction: ActionType {
    case viewAppear
    case loadHomeData
    case loadNextDayData
    case loadPreviousDayData
    case setHomeData(wakeDuration: Int?, memos: [MemosEntity], alarms: [AlarmsEntity], schedules: [SchedulesEntity])
    case appendNextDayData(memos: [MemosEntity], alarms: [AlarmsEntity], schedules: [SchedulesEntity])
    case prependPreviousDayData(memos: [MemosEntity], alarms: [AlarmsEntity], schedules: [SchedulesEntity])
    case setCurrentDisplayDate(Date)
    case setLoading(Bool)
    case setLoadingNextDay(Bool)
    case showAllMemos(Bool)
    case showAddMemos(Bool)
    case showEditMemos(Bool)
}
