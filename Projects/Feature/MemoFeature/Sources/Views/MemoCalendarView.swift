import SwiftUI
import Designsystem
import MemoFeatureInterface
import MemoDomainInterface
import Localization

struct MemoCalendarView: View {
    let interface: MemoInterface
    @State private var state = MemoState()
    @Environment(\.dismiss) private var dismiss
    
    init(interface: MemoInterface, state: MemoState) {
        self.interface = interface
        self._state = State(initialValue: state)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    calendarSection
                    memoListSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("HomeMemoCalendarTitle".localized())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                        interface.send(.showMemoDetail(false))
                    }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        let targetDate = state.selectedMemoDate
                        dismiss()
                        interface.send(.showMemoDetail(false))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            interface.send(.memoScheduledDateDidChange(targetDate))
                            interface.send(.showMemoSheet(true))
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
    
    private var calendarSection: some View {
        DatePicker(
            "",
            selection: Binding(
                get: { state.selectedMemoDate },
                set: { interface.send(.selectMemoDate($0)) }
            ),
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(JColor.card)
        )
        .tint(JColor.primaryVariant)
    }
    
    private var memoListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(
                String(
                    format: "HomeMemoCalendarSelectedDateTitle".localized(),
                    locale: Locale(identifier: LocalizationController.shared.languageCode),
                    formattedSelectedDate
                )
            )
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(JColor.textPrimary)
            
            if state.memosForSelectedDate.isEmpty {
                Text("HomeMemoCalendarEmpty".localized())
                    .font(.system(size: 15))
                    .foregroundStyle(JColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(JColor.border, lineWidth: 1)
                    )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(state.memosForSelectedDate, id: \.id) { memo in
                            memoCard(memo)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func memoCard(_ memo: MemoEntity) -> some View {
        Button(action: {
            dismiss()
            interface.send(.showMemoDetail(false))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                interface.send(.editMemo(memo))
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(memo.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(JColor.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if let reminder = formattedReminder(from: memo.reminderTime) {
                        Text(reminder)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(JColor.textSecondary)
                    }
                }
                Text(memo.content)
                    .font(.system(size: 14))
                    .foregroundStyle(JColor.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(JColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(JColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationController.shared.languageCode)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: state.selectedMemoDate)
    }
    
    private func formattedReminder(from isoString: String?) -> String? {
        guard let isoString,
              let date = MemoState.reminderTimeFormatter.date(from: isoString) else {
            return nil
        }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        if components.hour == 0 && components.minute == 0 {
            return nil
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationController.shared.languageCode)
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

