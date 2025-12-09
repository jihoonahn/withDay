import SwiftUI
import Rex
import MemosFeatureInterface
import Designsystem
import Utility

struct MemoAddView: View {
    let interface: MemoInterface
    @State var state: MemoState

    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 제목 입력
                        VStack(alignment: .leading, spacing: 12) {
                            Text("제목")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            TextField("메모 제목을 입력하세요", text: Binding(
                                get: { state.addMemoTitle },
                                set: { interface.send(.addMemoTitleDidChange($0)) }
                            ))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                            .foregroundColor(JColor.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        
                        // 내용 입력
                        VStack(alignment: .leading, spacing: 12) {
                            Text("내용")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            TextEditor(text: Binding(
                                get: { state.addMemoContent },
                                set: { interface.send(.addMemoContentDidChange($0)) }
                            ))
                            .frame(minHeight: 200)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                            .foregroundColor(JColor.textPrimary)
                            .scrollContentBackground(.hidden)
                        }
                        .padding(.horizontal, 20)
                        
                        // 날짜 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("날짜")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            DatePicker(
                                "날짜 선택",
                                selection: Binding(
                                    get: { state.addMemoScheduledDate },
                                    set: { interface.send(.addMemoScheduledDateDidChange($0)) }
                                ),
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                            .accentColor(JColor.primaryVariant)
                        }
                        .padding(.horizontal, 20)
                        
                        // 리마인더 설정
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("리마인더 설정", isOn: Binding(
                                get: { state.addMemoHasReminder },
                                set: { interface.send(.addMemoHasReminderDidChange($0)) }
                            ))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(JColor.textPrimary)
                            
                            if state.addMemoHasReminder {
                                DatePicker(
                                    "리마인더 시간",
                                    selection: Binding(
                                        get: { state.addMemoReminderTime ?? Date() },
                                        set: { interface.send(.addMemoReminderTimeDidChange($0)) }
                                    ),
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
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Add Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        interface.send(.setMemoFlow(.all))
                    }
                    .foregroundColor(JColor.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        interface.send(.addMemo(
                            state.editMemoTitle,
                            state.editMemoContent,
                            state.editMemoScheduledDate,
                            state.editMemoReminderTime,
                            state.editMemoHasReminder
                        ))
                    }
                    .foregroundColor(JColor.textPrimary)
                    .fontWeight(.semibold)
                    .disabled(state.addMemoTitle.isEmpty && state.addMemoContent.isEmpty)
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
