import Foundation
import Rex
import MemoFeatureInterface
import MemoDomainInterface
import UserDomainInterface
import Localization
import BaseFeature
import Utility

public struct MemoReducer: Reducer {
    private let userUseCase: UserUseCase
    private let memoUseCase: MemoUseCase

    public init(
        memoUseCase: MemoUseCase,
        userUseCase: UserUseCase,
    ) {
        self.memoUseCase = memoUseCase
        self.userUseCase = userUseCase
    }

    public func reduce(state: inout MemoState, action: MemoAction) -> [Effect<MemoAction>] {
        switch action {
        case .loadMemo:
            return [
                Effect { emitter in
                    do {
                        guard let user = try await userUseCase.getCurrentUser() else {
                            emitter.send(.showMemoToast("사용자 정보를 찾을 수 없습니다."))
                            return
                        }
                        
                        let memos = try await memoUseCase.fetchAll(userId: user.id)
                        emitter.send(.setMemos(memos))
                    } catch {
                        emitter.send(.showMemoToast("메모를 불러오는데 실패했습니다: \(error.localizedDescription)"))
                    }
                }
            ]
        case let .setMemos(memos):
            state.memos = memos
            return []
        case let .setMemoFlow(flow):
            state.flow = flow
            return []
        case let .addMemoTitleDidChange(title):
            state.addMemoTitle = title
            return []
        case let .addMemoContentDidChange(content):
            state.addMemoContent = content
            return []
        case let .addMemoScheduledDateDidChange(date):
            state.addMemoScheduledDate = date
            return []
        case let .addMemoReminderTimeDidChange(time):
            state.addMemoReminderTime = time
            return []
        case let .addMemoHasReminderDidChange(hasReminder):
            state.addMemoHasReminder = hasReminder
            return []
        case let .addMemo(title, content, scheduledDate, reminderTimeString, hasReminder):
            let reminderTime: String?
            if hasReminder, let time = reminderTimeString {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: time)
                let minute = calendar.component(.minute, from: time)
                reminderTime = String(format: "%02d:%02d", hour, minute)
            } else {
                reminderTime = nil
            }
            return [
                Effect { emitter in
                    do {
                        guard let user = try await userUseCase.getCurrentUser() else {
                            emitter.send(.showMemoToast("사용자 정보를 찾을 수 없습니다."))
                            return
                        }
                        
                        let memo = MemoEntity(
                            id: UUID(),
                            userId: user.id,
                            title: title,
                            content: content,
                            alarmId: nil,
                            reminderTime: reminderTime,
                            createdAt: scheduledDate,
                            updatedAt: Date()
                        )
                        
                        try await memoUseCase.create(memo)
                        emitter.send(.showMemoToast("메모를 저장했습니다."))
                        emitter.send(.setMemoFlow(.all))
                        
                        let memos = try await memoUseCase.fetchAll(userId: user.id)
                        emitter.send(.setMemos(memos))
                    } catch {
                        emitter.send(.showMemoToast("메모를 저장하는데 실패했습니다: \(error.localizedDescription)"))
                    }
                }
            ]
        case let .editMemoTitleDidChange(title):
            state.editMemoTitle = title
            return []
        case let .editMemoContentDidChange(content):
            state.editMemoContent = content
            return []
        case let .editMemoScheduledDateDidChange(date):
            state.editMemoScheduledDate = date
            return []
        case let .editMemoReminderTimeDidChange(time):
            state.editMemoReminderTime = time
            return []
        case let .editMemoHasReminderDidChange(hasReminder):
            state.editMemoHasReminder = hasReminder
            return []
        case .updateMemo:
            guard let existingMemo = state.editMemoState else {
                return [
                    .just(.showMemoToast("메모를 찾을 수 없습니다."))
                ]
            }
            let title = state.editMemoTitle
            let content = state.editMemoContent
            let scheduledDate = state.editMemoScheduledDate
            let reminderTimeString: String?
            if state.editMemoHasReminder, let time = state.editMemoReminderTime {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: time)
                let minute = calendar.component(.minute, from: time)
                reminderTimeString = String(format: "%02d:%02d", hour, minute)
            } else {
                reminderTimeString = nil
            }
            return [
                Effect { emitter in
                    do {
                        guard let user = try await userUseCase.getCurrentUser() else {
                            emitter.send(.showMemoToast("사용자 정보를 찾을 수 없습니다."))
                            return
                        }
                        
                        let updatedMemo = MemoEntity(
                            id: existingMemo.id,
                            userId: existingMemo.userId,
                            title: title,
                            content: content,
                            alarmId: existingMemo.alarmId,
                            reminderTime: reminderTimeString,
                            createdAt: scheduledDate,
                            updatedAt: Date()
                        )
                        
                        try await memoUseCase.update(updatedMemo)
                        emitter.send(.showMemoToast("메모를 수정했습니다."))
                        
                        let memos = try await memoUseCase.fetchAll(userId: user.id)
                        emitter.send(.setMemos(memos))
                    } catch {
                        emitter.send(.showMemoToast("메모를 수정하는데 실패했습니다: \(error.localizedDescription)"))
                    }
                }
            ]
        case let .deleteMemo(id):
            return [
                Effect { emitter in
                    do {
                        guard let user = try await userUseCase.getCurrentUser() else {
                            emitter.send(.showMemoToast("사용자 정보를 찾을 수 없습니다."))
                            return
                        }
                        try await memoUseCase.delete(id: id)
                        emitter.send(.showMemoToast("메모를 삭제했습니다."))
                        let memos = try await memoUseCase.fetchAll(userId: user.id)
                        emitter.send(.setMemos(memos))
                    } catch {
                        emitter.send(.showMemoToast("메모를 삭제하는데 실패했습니다: \(error.localizedDescription)"))
                    }
                }
            ]
        case let .showMemoToast(text):
            state.memoToastMessage = text
            return [
                .just(.memoToastStatus(true))
            ]
        case let .memoToastStatus(status):
            state.memoToastIsPresented = status
            return []
        case let .showEditMemo(item):
            state.editMemoState = item
            state.editMemoTitle = item.title
            state.editMemoContent = item.content
            state.editMemoScheduledDate = Calendar.current.startOfDay(for: item.createdAt ?? Date())
            if let reminderTimeString = item.reminderTime,
               let date = DateFormatter.reminderTimeFormatter.date(from: reminderTimeString) {
                state.editMemoHasReminder = true
                state.editMemoReminderTime = date
            } else {
                state.editMemoHasReminder = false
                state.editMemoReminderTime = nil
            }
            return []
        }
    }
}
