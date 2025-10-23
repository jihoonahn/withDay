import SwiftUI
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface
import Designsystem

public struct AlarmView: View {
    let interface: AlarmInterface
    @State private var state = AlarmState()
    @State private var showingAddAlarm = false
    @State private var selectedDate = Date()

    public init(
        interface: AlarmInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("알람")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                if state.alarms.isEmpty {
                                    Text("알람이 없습니다")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(JColor.textSecondary)
                                } else {
                                    Text("\(state.alarms.count)개의 알람")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(JColor.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddAlarm = true
                            }) {
                                Image(refineUIIcon: .add24Regular)
                                    .foregroundColor(JColor.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(JColor.primary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Alarm List
                        if state.isLoading {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: JColor.primary))
                                Text("로딩 중...")
                                    .font(.system(size: 14))
                                    .foregroundColor(JColor.textSecondary)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else if state.alarms.isEmpty {
                            VStack(spacing: 16) {
                                Image(refineUIIcon: .clockAlarm32Regular)
                                    .foregroundColor(JColor.textSecondary)
                                    .font(.system(size: 48))
                                
                                Text("알람이 없습니다")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(JColor.textSecondary)
                                
                                Text("+ 버튼을 눌러 알람을 추가하세요")
                                    .font(.system(size: 14))
                                    .foregroundColor(JColor.textSecondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(state.alarms, id: \.id) { alarm in
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Error Message
                        if let errorMessage = state.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(JColor.error)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddAlarm) {
        }
        .task {
            interface.send(.loadAlarms)
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
