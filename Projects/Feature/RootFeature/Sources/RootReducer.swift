import Rex
import RootFeatureInterface
import UsersDomainInterface

public struct RootReducer: Reducer {
    private let usersUseCase: UsersUseCase

    public init(usersUseCase: UsersUseCase) {
        self.usersUseCase = usersUseCase
    }

    public func reduce(state: inout RootState, action: RootAction) -> [Effect<RootAction>] {
        switch action {
        case .checkAutoLogin:
            return [
                Effect { emitter in
                    do {
                        if let _ = try await usersUseCase.getCurrentUser() {
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
