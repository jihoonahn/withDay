import Foundation
import Rex
import SettingFeatureInterface
import UserDomainInterface
import SettingDomainInterface
import Dependency
import BaseFeature

public struct SettingReducer: Reducer {
    private let userUseCase: UserUseCase
    private let settingUseCase: SettingUseCase?
    
    public init(userUseCase: UserUseCase) {
        self.userUseCase = userUseCase
        self.settingUseCase = DIContainer.shared.isRegistered(SettingUseCase.self)
            ? DIContainer.shared.resolve(SettingUseCase.self)
            : nil
    }
    
    private func getCurrentUserId() async throws -> UUID {
        guard let user = try await userUseCase.getCurrentUser() else {
            throw NSError(domain: "SettingReducer", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user.id
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
            
        // Language Settings
        case .loadLanguage:
            return [
                Effect { [self] emitter in
                    do {
                        let userId = try await getCurrentUserId()
                        if let language = try await self.settingUseCase?.getLanguage(userId: userId) {
                            emitter.send(.setLanguage(language))
                        }
                    } catch {
                        logger.error("Language load failed: \(error)")
                    }
                }
            ]
            
        case let .setLanguage(language):
            state.language = language
            return []
            
        case let .saveLanguage(language):
            return [
                Effect { [self] emitter in
                    do {
                        let userId = try await getCurrentUserId()
                        try await self.settingUseCase?.saveLanguage(userId: userId, language: language)
                        emitter.send(.setLanguage(language))
                    } catch {
                        logger.error("Language save failed: \(error)")
                    }
                }
            ]
            
        // Notification Settings
        case .loadNotificationSetting:
            return [
                Effect { [self] emitter in
                    do {
                        let userId = try await getCurrentUserId()
                        if let enabled = try await self.settingUseCase?.getNotificationSetting(userId: userId) {
                            emitter.send(.setNotificationSetting(enabled))
                        }
                    } catch {
                        logger.error("Notification setting load failed: \(error)")
                    }
                }
            ]
            
        case let .setNotificationSetting(enabled):
            state.notificationEnabled = enabled
            return []
            
        case let .saveNotificationSetting(enabled):
            return [
                Effect { [self] emitter in
                    do {
                        let userId = try await getCurrentUserId()
                        try await self.settingUseCase?.saveNotificationSetting(userId: userId, enabled: enabled)
                        emitter.send(.setNotificationSetting(enabled))
                    } catch {
                        logger.error("Notification setting save failed: \(error)")
                    }
                }
            ]
        }
    }
}
