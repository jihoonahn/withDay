import SwiftUI
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface
import UserDomainInterface
import Designsystem
import Dependency
import Localization

public struct AlarmView: View {
    let interface: AlarmInterface
    @State private var state = AlarmState()

    public init(
        interface: AlarmInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                List {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AlarmTitle".localized())
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                if state.alarms.isEmpty {
                                    Text("AlarmEmptyStateTitle".localized())
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(JColor.textSecondary)
                                } else {
                                    Text(String(
                                        format: "AlarmDescription".localized(),
                                        locale: Locale.appLocale,
                                        state.alarms.count
                                    ))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(JColor.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                interface.send(.showingAddAlarmState(true))
                            }) {
                                Image(refineUIIcon: .add24Regular)
                                    .foregroundColor(JColor.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .glassEffect(.clear.interactive(), in: .circle)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))
                    }
                    
                    if state.isLoading {
                        Section {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: JColor.primary))
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 40, leading: 20, bottom: 40, trailing: 20))
                        }
                    } else if state.alarms.isEmpty {
                        Section {
                            VStack(spacing: 16) {
                                Image(refineUIIcon: .clockAlarm32Regular)
                                    .foregroundColor(JColor.textSecondary)
                                    .font(.system(size: 48))
                                
                                Text("AlarmEmptyStateTitle".localized())
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(JColor.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                        }
                    } else {
                        Section {
                            ForEach(state.alarms, id: \.id) { alarm in
                                AlarmRow(
                                    alarm: alarm,
                                    onToggle: {
                                        interface.send(.toggleAlarm(id: alarm.id))
                                    },
                                    onTap: {
                                        interface.send(.showingEditAlarmState(alarm))
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        interface.send(.deleteAlarm(id: alarm.id))
                                    } label: {
                                        Label("AlarmActionDelete".localized(), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    
                    if let errorMessage = state.errorMessage {
                        Section {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(JColor.error)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: Binding(get: {
            state.showingAddAlarm
        }, set: { newValue in
            interface.send(.showingAddAlarmState(newValue))
        })) {
            AddAlarmSheet(
                isPresented: Binding(get: {
                    state.showingAddAlarm
                }, set: { newValue in
                    interface.send(.showingAddAlarmState(newValue))
                }),
                onSave: { time, label, repeatDays in
                    interface.send(.createAlarm(time: time, label: label, repeatDays: repeatDays))
                }
            )
        }
        .sheet(item: Binding(get: {
            state.editingAlarm
        }, set: { alarm in
            interface.send(.showingEditAlarmState(alarm))
        })) { alarm in
            EditAlarmSheet(
                alarm: alarm,
                isPresented: Binding(get: {
                    state.editingAlarm != nil
                }, set: { isPresented in
                    if !isPresented {
                        interface.send(.showingEditAlarmState(nil))
                    }
                }),
                onSave: { id, time, label, repeatDays in
                    interface.send(.updateAlarmWithData(id: id, time: time, label: label, repeatDays: repeatDays))
                }
            )
        }
        .task {
            interface.send(.loadAlarms)
        }
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}

// MARK: - AlarmRow
private struct AlarmRow: View {
    let alarm: AlarmEntity
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(alarm.time))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(alarm.isEnabled ? JColor.textPrimary : JColor.textSecondary)
                
                if let label = alarm.label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(alarm.isEnabled ? JColor.textSecondary : JColor.textDisabled)
                }
                
                if !alarm.repeatDays.isEmpty {
                    Text(formatRepeatDays(alarm.repeatDays))
                        .font(.system(size: 12))
                        .foregroundColor(alarm.isEnabled ? JColor.textSecondary : JColor.textDisabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(JColor.success)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(JColor.card)
                .shadow(color: JColor.background.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        let cleanTime: String
        if timeString.contains(" ") {
            let parts = timeString.split(separator: " ")
            cleanTime = parts.count >= 2 ? String(parts[1]) : timeString
        } else {
            cleanTime = timeString
        }
        
        let components = cleanTime.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString
        }
        
        return String(format: "%02d:%02d", hour, minute)
    }
    
    private func formatRepeatDays(_ days: [Int]) -> String {
        if days.count == 7 {
            return "AlarmRepeatEveryday".localized()
        }
        
        let sortedDays = days.sorted()
        
        if sortedDays == [1, 2, 3, 4, 5] {
            return "AlarmRepeatWeekdays".localized()
        }
        
        if sortedDays == [0, 6] {
            return "AlarmRepeatWeekend".localized()
        }
        
        return sortedDays
            .map { localizedDayName(for: $0) }
            .joined(separator: ", ")
    }
}

// MARK: - AddAlarmSheet
private struct AddAlarmSheet: View {
    @Binding var isPresented: Bool
    let onSave: (String, String?, [Int]) -> Void
    
    @State private var selectedTime = Date()
    @State private var label = ""
    @State private var selectedDays: Set<Int> = []
    @State private var isRepeating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 알람 타입 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AlarmTypeSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            Picker("", selection: $isRepeating) {
                                Text("AlarmTypeOnce".localized()).tag(false)
                                Text("AlarmTypeRepeat".localized()).tag(true)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: isRepeating) { _, newValue in
                                if !newValue {
                                    selectedDays.removeAll()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 시간 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AlarmTimeSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            DatePicker(
                                "",
                                selection: $selectedTime,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // 라벨
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AlarmLabelSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            TextField("AlarmLabelPlaceholder".localized(), text: $label)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                                .foregroundColor(JColor.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        
                        // 반복 요일 (반복 알람일 때만)
                        if isRepeating {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("AlarmRepeatDaysSectionTitle".localized())
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                HStack(spacing: 6) {
                                    // 월-일 순서로 표시 (1,2,3,4,5,6,0)
                                    ForEach([1, 2, 3, 4, 5, 6, 0], id: \.self) { day in
                                        DayButton(
                                            day: day,
                                            isSelected: selectedDays.contains(day),
                                            onTap: {
                                                if selectedDays.contains(day) {
                                                    selectedDays.remove(day)
                                                } else {
                                                    selectedDays.insert(day)
                                                }
                                            }
                                        )
                                    }
                                }
                                
                                // 빠른 선택 버튼
                                HStack(spacing: 8) {
                                    QuickSelectButton(
                                        title: "AlarmQuickSelectWeekdays".localized(),
                                        icon: "briefcase.fill",
                                        isActive: selectedDays == [1, 2, 3, 4, 5]
                                    ) {
                                        selectedDays = [1, 2, 3, 4, 5]
                                    }
                                    
                                    QuickSelectButton(
                                        title: "AlarmQuickSelectWeekends".localized(),
                                        icon: "sun.max.fill",
                                        isActive: selectedDays == [0, 6]
                                    ) {
                                        selectedDays = [0, 6]
                                    }
                                    
                                    QuickSelectButton(
                                        title: "AlarmQuickSelectEveryday".localized(),
                                        icon: "calendar",
                                        isActive: selectedDays.count == 7
                                    ) {
                                        selectedDays = Set(0..<7)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("AlarmAddNavigationTitle".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("CommonCancel".localized()) {
                        isPresented = false
                    }
                    .foregroundColor(Color.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("CommonSave".localized()) {
                        saveAlarm()
                    }
                    .foregroundColor(Color.white)
                    .fontWeight(.semibold)
                    .disabled(isRepeating && selectedDays.isEmpty)
                }
            }
        }
    }
    
    private func saveAlarm() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedTime)
        let minute = calendar.component(.minute, from: selectedTime)
        let timeString = String(format: "%02d:%02d", hour, minute)
        
        let alarmLabel = label.isEmpty ? nil : label
        let repeatDays = isRepeating ? Array(selectedDays).sorted() : []
        
        // Reducer로 데이터만 전달 (비즈니스 로직은 Reducer에서 처리)
        // 시트 닫기는 Reducer에서 성공 시 자동으로 처리됨
        onSave(timeString, alarmLabel, repeatDays)
    }
}

// MARK: - EditAlarmSheet
private struct EditAlarmSheet: View {
    let alarm: AlarmEntity
    @Binding var isPresented: Bool
    let onSave: (UUID, String, String?, [Int]) -> Void
    
    @State private var selectedTime: Date
    @State private var label: String
    @State private var selectedDays: Set<Int>
    @State private var isRepeating: Bool
    
    init(alarm: AlarmEntity, isPresented: Binding<Bool>, onSave: @escaping (UUID, String, String?, [Int]) -> Void) {
        self.alarm = alarm
        self._isPresented = isPresented
        self.onSave = onSave
        
        // 시간 파싱
        let timeComponents = alarm.time.split(separator: ":")
        let hour = timeComponents.count >= 1 ? Int(timeComponents[0]) ?? 0 : 0
        let minute = timeComponents.count >= 2 ? Int(timeComponents[1]) ?? 0 : 0
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        self._selectedTime = State(initialValue: Calendar.current.date(from: dateComponents) ?? Date())
        
        self._label = State(initialValue: alarm.label ?? "")
        self._selectedDays = State(initialValue: Set(alarm.repeatDays))
        self._isRepeating = State(initialValue: !alarm.repeatDays.isEmpty)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AlarmTypeSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            Picker("", selection: $isRepeating) {
                                Text("AlarmTypeOnce".localized()).tag(false)
                                Text("AlarmTypeRepeat".localized()).tag(true)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: isRepeating) { _, newValue in
                                if !newValue {
                                    selectedDays.removeAll()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 시간 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AlarmTimeSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            DatePicker(
                                "",
                                selection: $selectedTime,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // 라벨
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AlarmLabelSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            TextField("AlarmLabelPlaceholder".localized(), text: $label)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                                .foregroundColor(JColor.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        
                        // 반복 요일 (반복 알람일 때만)
                        if isRepeating {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("AlarmRepeatDaysSectionTitle".localized())
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                HStack(spacing: 6) {
                                    ForEach([1, 2, 3, 4, 5, 6, 0], id: \.self) { day in
                                        DayButton(
                                            day: day,
                                            isSelected: selectedDays.contains(day),
                                            onTap: {
                                                if selectedDays.contains(day) {
                                                    selectedDays.remove(day)
                                                } else {
                                                    selectedDays.insert(day)
                                                }
                                            }
                                        )
                                    }
                                }
                                
                                // 빠른 선택 버튼
                                HStack(spacing: 8) {
                                    QuickSelectButton(
                                        title: "AlarmQuickSelectWeekdays".localized(),
                                        icon: "briefcase.fill",
                                        isActive: selectedDays == [1, 2, 3, 4, 5]
                                    ) {
                                        selectedDays = [1, 2, 3, 4, 5]
                                    }
                                    
                                    QuickSelectButton(
                                        title: "AlarmQuickSelectWeekends".localized(),
                                        icon: "sun.max.fill",
                                        isActive: selectedDays == [0, 6]
                                    ) {
                                        selectedDays = [0, 6]
                                    }
                                    
                                    QuickSelectButton(
                                        title: "AlarmQuickSelectEveryday".localized(),
                                        icon: "calendar",
                                        isActive: selectedDays.count == 7
                                    ) {
                                        selectedDays = Set(0..<7)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("AlarmEditNavigationTitle".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("CommonCancel".localized()) {
                        isPresented = false
                    }
                    .foregroundColor(Color.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("CommonSave".localized()) {
                        saveAlarm()
                    }
                    .foregroundColor(Color.white)
                    .fontWeight(.semibold)
                    .disabled(isRepeating && selectedDays.isEmpty)
                }
            }
        }
    }
    
    private func saveAlarm() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedTime)
        let minute = calendar.component(.minute, from: selectedTime)
        let timeString = String(format: "%02d:%02d", hour, minute)
        
        let alarmLabel = label.isEmpty ? nil : label
        let repeatDays = isRepeating ? Array(selectedDays).sorted() : []
        
        onSave(alarm.id, timeString, alarmLabel, repeatDays)
    }
}

// MARK: - DayButton
private struct DayButton: View {
    let day: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(localizedDayName(for: day))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : JColor.textSecondary)
            }
            .frame(width: 42, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? JColor.primary : JColor.card)
                    .shadow(
                        color: isSelected ? JColor.primary.opacity(0.3) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - QuickSelectButton
private struct QuickSelectButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isActive ? .white : JColor.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? JColor.primary : JColor.card)
                    .shadow(
                        color: isActive ? JColor.primary.opacity(0.2) : .clear,
                        radius: 6,
                        x: 0,
                        y: 3
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private func localizedDayName(for day: Int) -> String {
    switch day {
    case 0:
        return "AlarmDaySunday".localized()
    case 1:
        return "AlarmDayMonday".localized()
    case 2:
        return "AlarmDayTuesday".localized()
    case 3:
        return "AlarmDayWednesday".localized()
    case 4:
        return "AlarmDayThursday".localized()
    case 5:
        return "AlarmDayFriday".localized()
    case 6:
        return "AlarmDaySaturday".localized()
    default:
        return ""
    }
}

private extension Locale {
    static var appLocale: Locale {
        Locale(identifier: LocalizationController.shared.languageCode)
    }
}
