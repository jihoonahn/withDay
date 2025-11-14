import Foundation
import SwiftUI
import Rex
import RootFeatureInterface
import MotionFeatureInterface
import Designsystem
import Localization
import MotionRawDataDomainInterface

public struct MotionView: View {
    let interface: MotionInterface
    @State private var state = MotionState()

    public init(
        interface: MotionInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        ZStack {
            JColor.background.ignoresSafeArea()
            
            if state.isMonitoring {
                VStack(spacing: 40) {
                    Spacer()
                    
                    // 카운트 표시 (중점)
                    VStack(spacing: 20) {
                        Text("\(state.motionCount)")
                            .font(.system(size: 120, weight: .bold, design: .rounded))
                            .foregroundColor(JColor.primaryVariant)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.motionCount)
                        
                        Text("\(state.requiredCount)")
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .foregroundColor(JColor.textSecondary)
                            .opacity(0.6)
                    }
                    
                    // 진행 바
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(JColor.card)
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(JColor.primaryVariant)
                                .frame(
                                    width: geometry.size.width * min(CGFloat(state.motionCount) / CGFloat(state.requiredCount), 1.0),
                                    height: 12
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.motionCount)
                        }
                    }
                    .frame(height: 12)
                    .padding(.horizontal, 60)
                    
                    // 안내 텍스트
                    VStack(spacing: 12) {
                        Text("기기를 흔들어주세요")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(JColor.textPrimary)
                        
                        Text("\(state.requiredCount)번 흔들면 알람이 종료됩니다")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(JColor.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 60)
            } else {
                // 모니터링이 끝났을 때
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(JColor.success)
                    
                    Text("알람이 종료되었습니다")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(JColor.textPrimary)
                }
            }
        }
        .interactiveDismissDisabled(state.isMonitoring)
        .onAppear {
            interface.send(.viewAppear)
        }
        .task {
            // State 스트림 구독
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
