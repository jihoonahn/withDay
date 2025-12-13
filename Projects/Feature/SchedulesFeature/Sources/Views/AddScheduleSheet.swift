import SwiftUI
import SchedulesFeatureInterface
import Designsystem
import Localization

struct AddScheduleSheet: View {
    let interface: SchedulesInterface
    @State private var state = SchedulesState()
    
    init(interface: SchedulesInterface) {
        self.interface = interface
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 제목
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ScheduleTitleSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            TextField("ScheduleTitlePlaceholder".localized(), text: Binding(get: {
                                state.title
                            }, set: { value in
                                interface.send(.titleTextFieldDidChange(value))
                            }))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                            .foregroundColor(JColor.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        
                        // 설명
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ScheduleDescriptionSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            TextField("ScheduleDescriptionPlaceholder".localized(), text: Binding(get: {
                                state.description
                            }, set: { value in
                                interface.send(.descriptionTextFieldDidChange(value))
                            }), axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                            .foregroundColor(JColor.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        
                        // 날짜 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ScheduleDateSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            DatePicker(
                                "",
                                selection: Binding(get: {
                                    state.selectedDate
                                }, set: { newValue in
                                    interface.send(.datePickerDidChange(newValue))
                                }),
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // 시간 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ScheduleTimeSectionTitle".localized())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            // 시작 시간
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ScheduleStartTime".localized())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(JColor.textSecondary)
                                
                                DatePicker(
                                    "",
                                    selection: Binding(get: {
                                        state.startTime
                                    }, set: { newValue in
                                        interface.send(.startTimePickerDidChange(newValue))
                                    }),
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                            }
                            
                            // 종료 시간
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ScheduleEndTime".localized())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(JColor.textSecondary)
                                
                                DatePicker(
                                    "",
                                    selection: Binding(get: {
                                        state.endTime
                                    }, set: { newValue in
                                        interface.send(.endTimePickerDidChange(newValue))
                                    }),
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("ScheduleAddNavigationTitle".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("CommonCancel".localized()) {
                        interface.send(.showingAddSchedule(false))
                    }
                    .foregroundColor(Color.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("CommonSave".localized()) {
                        interface.send(.saveAddSchedule)
                    }
                    .foregroundColor(Color.white)
                    .fontWeight(.semibold)
                    .disabled(state.title.isEmpty)
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
}
