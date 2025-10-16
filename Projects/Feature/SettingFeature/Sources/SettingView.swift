import SwiftUI
import Rex
import SettingFeatureInterface
import Designsystem

public struct SettingView: View {
    let interface: SettingInterface
    @State private var state = SettingState()

    public init(
        interface: SettingInterface
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
                                Text("설정")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                Text("앱 설정을 관리하세요")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(JColor.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 여기에 설정 컨텐츠 추가
                        Text("Setting Content")
                            .font(.title)
                            .foregroundColor(JColor.textPrimary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.bottom, 100)
                }
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
