import SwiftUI
import Rex
import RootFeatureInterface
import LoginFeatureInterface
import MainFeatureInterface
import Dependency

public struct RootView: View {
    let interface: RootInterface
    @State private var state = RootState()

    private let loginFactory: LoginFactory
    private let mainFactory: MainFactory

    public init(
        interface: RootInterface
    ) {
        self.interface = interface
        self.loginFactory = DIContainer.shared.resolve(LoginFactory.self)
        self.mainFactory = DIContainer.shared.resolve(MainFactory.self)
    }
    
    public var body: some View {
        Group {
            switch state.flow {
            case .login:
                loginFactory.makeView()
            case .main:
                mainFactory.makeView()
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
