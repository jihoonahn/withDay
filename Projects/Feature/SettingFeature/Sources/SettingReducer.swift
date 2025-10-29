import Rex
import SettingFeatureInterface
import UserDomainInterface
import BaseFeature

public struct SettingReducer: Reducer {
    private let userUseCase: UserUseCase
    
    public init(userUseCase: UserUseCase) {
        self.userUseCase = userUseCase
    }
    
    public func reduce(state: inout SettingState, action: SettingAction) -> [Effect<SettingAction>] {
        switch action {
        case .fetchUserInformation:
            return [
                Effect { emitter in
                    do {
                        let user = try await userUseCase.getCurrentUser()
                        let name = user?.displayName ?? ""
                        let email = user?.email ?? ""
                        emitter.send(.setUserInformation(name: name, email: email))
                    } catch {
                        logger.error("User Information Not Found")
                    }
                }
            ]

        case let .setUserInformation(name, email):
            return [
                .just(.emailTextDidChanged(email)),
                .just(.nameTextDidChanged(name))
            ]
        case let .nameTextDidChanged(text):
            state.name = text
            return []
            
        case let .emailTextDidChanged(text):
            state.email = text
            return []
            
        case .deleteUserAccount:
            print("Delete User")
            return []
            
        case .logout:
            return [
                Effect { emitter in
                    do {
                        try await userUseCase.logout()
                        await GlobalEventBus.shared.publish(RootEvent.logout)
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    } catch {
                        await GlobalEventBus.shared.publish(RootEvent.logout)
                    }
                }
            ]
        }
    }
}
