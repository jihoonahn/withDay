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
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Alarm")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                Text("3시간 30분 후 기상")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(JColor.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // 알람 추가 액션
                            }) {
                                Image(refineUIIcon: .add24Regular)
                                    .foregroundColor(JColor.primary)
                                    .frame(width: 40, height: 40)
                                    .background(JColor.primary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        VStack(spacing: 18) {
                            
                        }
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
