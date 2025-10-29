import SwiftUI
import Rex
import RootFeatureInterface
import SplashFeatureInterface
import LoginFeatureInterface
import MainFeatureInterface
import Dependency
import Designsystem

public struct RootView: View {
    let interface: RootInterface
    @State private var state = RootState()
    @State private var hasCheckedAutoLogin = false

    private let splashFactory: SplashFactory
    private let loginFactory: LoginFactory
    private let mainFactory: MainFactory

    public init(
        interface: RootInterface
    ) {
        self.interface = interface
        self.splashFactory = DIContainer.shared.resolve(SplashFactory.self)
        self.loginFactory = DIContainer.shared.resolve(LoginFactory.self)
        self.mainFactory = DIContainer.shared.resolve(MainFactory.self)
    }
    
    public var body: some View {
        Group {
            switch state.flow {
            case .splash:
                splashFactory.makeView()
            case .login:
                loginFactory.makeView()
            case .main:
                mainFactory.makeView()
            }
        }
        .task {
            if !hasCheckedAutoLogin {
                interface.send(.checkAutoLogin)
            }

            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
