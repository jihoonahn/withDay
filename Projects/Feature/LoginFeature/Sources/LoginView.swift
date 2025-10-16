import SwiftUI
import Rex
import RootFeatureInterface
import LoginFeatureInterface
import Designsystem

public struct LoginView: View {
    let interface: LoginInterface
    @State private var state = LoginState()

    public init(
        interface: LoginInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        ZStack {
            // 배경
            JColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("WithDay")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("당신의 하루를 더 특별하게")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        interface.send(.selectToAppleOauth)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Apple로 계속하기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }

                    Button(action: {
                        interface.send(.selectToGoogleOauth)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                            
                            Text("Google로 계속하기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 32)
                Spacer()
                    .frame(height: 80)
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
