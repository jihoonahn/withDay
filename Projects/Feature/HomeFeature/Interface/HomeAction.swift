import Foundation
import Rex
import MemosDomainInterface
import AlarmsDomainInterface
import SchedulesDomainInterface

public enum HomeAction: ActionType {
    case viewAppear
    case loadHomeData
    case setHomeData(wakeDuration: Int?, memos: [MemosEntity], alarms: [AlarmsEntity], schedules: [SchedulesEntity])
    case setLoading(Bool)
    case showAllMemos(Bool)
    case showAddMemos(Bool)
    case showEditMemos(Bool)
}
