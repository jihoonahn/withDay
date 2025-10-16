import SwiftUI
import Rex
import AlarmFeatureInterface
import Designsystem

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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 헤더
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("알람")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                Text("\(state.alarms.count)개의 알람")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(JColor.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // 알람 추가 액션
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(JColor.primary)
                                    .frame(width: 40, height: 40)
                                    .background(JColor.primary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 여기에 알람 목록 추가
                        Text("Alarm Content")
                            .font(.title)
                            .foregroundColor(JColor.textPrimary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.bottom, 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}