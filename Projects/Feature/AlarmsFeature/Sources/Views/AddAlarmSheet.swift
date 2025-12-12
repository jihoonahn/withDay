import SwiftUI
import AlarmsFeatureInterface
import Designsystem

struct AddAlarmSheet: View {
    let interface: AlarmInterface
    @State private var state = AlarmState()
    
    init(interface: AlarmInterface) {
        self.interface = interface
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 시간 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AlarmTimeSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)

                            DatePicker(
                                "",
                                selection: Binding(get: {
                                    state.date
                                }, set: { newValue in
                                    interface.send(.datePickerDidChange(newValue))
                                }),
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
                            
                            TextField("AlarmLabelPlaceholder".localized(), text: Binding(get: {
                                state.label
                            }, set: { value in
                                interface.send(.labelTextFieldDidChange(value))
                            }))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                                .foregroundColor(JColor.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        
                        // 반복 요일 (반복 알람일 때만)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AlarmRepeatDaysSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            HStack(spacing: 6) {
                                // 월-일 순서로 표시 (1,2,3,4,5,6,0)
                                ForEach([1, 2, 3, 4, 5, 6, 0], id: \.self) { day in
                                    Button(action: {
                                        interface.send(.toggleRepeatDay(day))
                                    }) {
                                        Text(dayName(for: day))
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(state.selectedDays.contains(day) ? .white : JColor.textSecondary)
                                            .frame(width: 42, height: 42)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(state.selectedDays.contains(day) ? JColor.primary : JColor.card)
                                                    .shadow(
                                                        color: state.selectedDays.contains(day) ? JColor.primary.opacity(0.3) : .clear,
                                                        radius: 8,
                                                        x: 0,
                                                        y: 4
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // 빠른 선택 버튼
                            HStack(spacing: 8) {
                                Button(action: {
                                    interface.send(.setRepeatDays([1, 2, 3, 4, 5]))
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "briefcase.fill")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text("AlarmQuickSelectWeekdays".localized())
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(state.selectedDays == [1, 2, 3, 4, 5] ? .white : JColor.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(state.selectedDays == [1, 2, 3, 4, 5] ? JColor.primary : JColor.card)
                                            .shadow(
                                                color: state.selectedDays == [1, 2, 3, 4, 5] ? JColor.primary.opacity(0.2) : .clear,
                                                radius: 6,
                                                x: 0,
                                                y: 3
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    interface.send(.setRepeatDays([0, 6]))
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text("AlarmQuickSelectWeekends".localized())
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(state.selectedDays == [0, 6] ? .white : JColor.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(state.selectedDays == [0, 6] ? JColor.primary : JColor.card)
                                            .shadow(
                                                color: state.selectedDays == [0, 6] ? JColor.primary.opacity(0.2) : .clear,
                                                radius: 6,
                                                x: 0,
                                                y: 3
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    interface.send(.setRepeatDays(Set(0..<7)))
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text("AlarmQuickSelectEveryday".localized())
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(state.selectedDays.count == 7 ? .white : JColor.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(state.selectedDays.count == 7 ? JColor.primary : JColor.card)
                                            .shadow(
                                                color: state.selectedDays.count == 7 ? JColor.primary.opacity(0.2) : .clear,
                                                radius: 6,
                                                x: 0,
                                                y: 3
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        
                        
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
                        interface.send(.showingAddAlarmState(false))
                    }
                    .foregroundColor(Color.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("CommonSave".localized()) {
                        interface.send(.saveAddAlarm)
                    }
                    .foregroundColor(Color.white)
                    .fontWeight(.semibold)
                    .disabled(state.isRepeating && state.selectedDays.isEmpty)
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
    
    private func dayName(for day: Int) -> String {
        let calendar = Calendar.current
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let calendarDay = day == 0 ? 1 : day + 1
        if calendarDay >= 1 && calendarDay <= 7 {
            return weekdaySymbols[calendarDay - 1]
        }
        return ""
    }
}
