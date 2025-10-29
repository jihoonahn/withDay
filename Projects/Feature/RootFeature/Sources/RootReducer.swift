import Rex
import RootFeatureInterface
import UserDomainInterface

public struct RootReducer: Reducer {
    private let userUseCase: UserUseCase

    public init(userUseCase: UserUseCase) {
        self.userUseCase = userUseCase
    }

    public func reduce(state: inout RootState, action: RootAction) -> [Effect<RootAction>] {
        switch action {
        case .checkAutoLogin:
            return [
                Effect { emitter in
                    do {
                        if let _ = try await userUseCase.getCurrentUser() {
                            emitter.send(.switchToMain)
                        } else {
                            emitter.send(.switchToLogin)
                        }
                    } catch {
                        emitter.send(.switchToLogin)
                    }
                }
            ]
            
        case .switchToLogin:
            state.flow = .login
            return []

        case .switchToMain:
            state.flow = .main
            return []
        }
    }
}
