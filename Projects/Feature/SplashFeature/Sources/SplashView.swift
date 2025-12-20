import SwiftUI
import Rex
import SplashFeatureInterface
import Dependency
import Designsystem

public struct SplashView: View {
    let interface: SplashInterface
    @State private var state = SplashState()

    public init(
        interface: SplashInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        ZStack {
            JColor.background
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Image("launch", bundle: .main)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 76)
                    .padding(.top, 27)
                Spacer()
                VStack(spacing: 10) {
                    Text("from")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image("copyright", bundle: .main)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                }
                .padding(.bottom, 25)
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
