import SwiftUI
import Rex
import Designsystem
import HomeFeatureInterface
import Localization

struct MemoView: View {
    let interface: HomeInterface
    @State private var state = HomeState()
    @Environment(\.dismiss) private var dismiss

    init(interface: HomeInterface, state: HomeState) {
        self.interface = interface
        self._state = State(initialValue: state)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        dateField
                        titleField
                        contentField
                        reminderSection
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("HomeMemoSheetTitle".localized())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                        interface.send(.showMemoSheet(false))
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
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
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HomeMemoFormHeader".localized())
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
            
            Text("HomeMemoFormDescription".localized())
                .font(.system(size: 15))
                .foregroundStyle(JColor.textSecondary)
        }
    }
    
    private var dateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HomeMemoFormDateLabel".localized())
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            DatePicker(
                "",
                selection: Binding(
                    get: { state.memoScheduledDate },
                    set: { interface.send(.memoScheduledDateDidChange($0)) }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(JColor.card)
            )
            .tint(JColor.primaryVariant)
        }
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HomeMemoFormTitleLabel".localized())
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            JTextField(
                "HomeMemoFormTitlePlaceholder".localized(),
                text: Binding(
                    get: { state.memoTitle },
                    set: { interface.send(.memoTitleDidChange($0)) }
                )
            )
        }
    }
    
    private var contentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HomeMemoFormContentLabel".localized())
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            
            ZStack(alignment: .topLeading) {
                if state.memoContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("HomeMemoFormContentPlaceholder".localized())
                        .font(.system(size: 15))
                        .foregroundStyle(JColor.textSecondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                }
                
                TextEditor(
                    text: Binding(
                        get: { state.memoContent },
                        set: { interface.send(.memoContentDidChange($0)) }
                    )
                )
                .scrollContentBackground(.hidden)
                .font(.system(size: 15))
                .frame(minHeight: 160)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(JColor.card)
                .cornerRadius(16)
                .foregroundStyle(JColor.textPrimary)
            }
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { state.reminderTime != nil },
                set: { isOn in
                    if isOn {
                        interface.send(.memoReminderTimeDidChange(defaultReminderTime))
                    } else {
                        interface.send(.memoReminderTimeDidChange(nil))
                    }
                }
            )) {
                Text("HomeMemoFormReminderToggle".localized())
                    .foregroundStyle(.white)
                    .font(.system(size: 15, weight: .medium))
            }
            .tint(JColor.success)
            
            if let reminderTime = state.reminderTime {
                DatePicker(
                    "HomeMemoFormReminderLabel".localized(),
                    selection: Binding(
                        get: { reminderTime },
                        set: { interface.send(.memoReminderTimeDidChange($0)) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(JColor.card)
                )
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var defaultReminderTime: Date {
        let calendar = Calendar.current
        let baseDate = state.memoScheduledDate
        return calendar.date(
            bySettingHour: 7,
            minute: 0,
            second: 0,
            of: baseDate
        ) ?? baseDate
    }
    
    private var saveButton: some View {
        Button(action: {
            interface.send(.saveMemo)
        }) {
            HStack {
                if state.isSavingMemo {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Text("HomeMemoFormSaveButton".localized())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(state.isSavingMemo ? JColor.textSecondary : JColor.primaryVariant)
            .cornerRadius(16)
        }
        .disabled(state.isSavingMemo)
        .padding(.top, 10)
    }
}
