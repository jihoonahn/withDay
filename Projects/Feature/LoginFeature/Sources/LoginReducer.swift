import Rex
import LoginFeatureInterface
import UsersDomainInterface

public struct LoginReducer: Reducer {
    private let usersUseCase: UsersUseCase
    
    public init(usersUseCase: UsersUseCase) {
        self.usersUseCase = usersUseCase
    }
    
    public func reduce(state: inout LoginState, action: LoginAction) -> [Effect<LoginAction>] {
        switch action {
        case .selectToAppleOauth:
            state.isLoading = true
            return [
                Effect { emitter in
                    do {
                        let _ = try await usersUseCase.login(
                            provider: "apple",
                            email: nil,
                            displayName: nil
                        )
                        emitter.send(.loginSuccess)
                    } catch {
                        emitter.send(.loginFailure)
                    }
                }
            ]
            
        case .selectToGoogleOauth:
            state.isLoading = true
            return [
                Effect { emitter in
                    do {
                        let _ = try await usersUseCase.login(
                            provider: "google",
                            email: nil,
                            displayName: nil
                        )
                        emitter.send(.loginSuccess)
                    } catch {
                        emitter.send(.loginFailure)
                    }
                }
            ]
            
        case .loginSuccess:
            state.isLoading = false
            state.isLoggedIn = true
            return []
            
        case .loginFailure:
            state.isLoading = false
            state.isLoggedIn = false
            return []
            
        case let .toggleLoading(status):
            state.isLoading = status
            return []
        }
    }
}
