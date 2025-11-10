import Foundation
import Rex
import SettingFeatureInterface
import UserDomainInterface
import LocalizationDomainInterface
import NotificationDomainInterface
import Dependency
import BaseFeature
import Localization

public struct SettingReducer: Reducer {
    private let userUseCase: UserUseCase
    private let localizationUseCase: LocalizationUseCase
    private let notificationUseCase: NotificationUseCase
    
    public init(
        userUseCase: UserUseCase,
        localizationUseCase: LocalizationUseCase,
        notificationUseCase: NotificationUseCase
    ) {
        self.userUseCase = userUseCase
        self.localizationUseCase = localizationUseCase
        self.notificationUseCase = notificationUseCase
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
                .just(.nameTextDidChanged(name)),
                .just(.emailTextDidChanged(email))
            ]
        case let .nameTextDidChanged(text):
            state.name = text
            return []
            
        case let .emailTextDidChanged(text):
            state.email = text
            return []
        
        case let .saveProfile(name):
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return [
                Effect { emitter in
                    do {
                        guard var currentUser = try await userUseCase.getCurrentUser() else {
                            logger.error("Save User failed: Current user not found")
                            emitter.send(.showToast("사용자 정보를 찾을 수 없습니다."))
                            return
                        }
                        print(currentUser)
                        currentUser.displayName = trimmedName.isEmpty ? nil : trimmedName
                        try await userUseCase.updateUser(currentUser)
                        emitter.send(.setUserInformation(name: currentUser.displayName ?? "", email: currentUser.email ?? ""))
                        emitter.send(.showToast("프로필이 저장되었습니다."))
                    } catch {
                        logger.error("Save User failed: \(error)")
                        emitter.send(.showToast("프로필 저장에 실패했습니다."))
                    }
                }
            ]
            
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
                Effect { emitter in
                    do {
                        let userId = try await self.getCurrentUserId()
                        let availableLanguages = try await self.localizationUseCase.fetchAvailableLocalizations()
                        emitter.send(.setAvailableLanguages(availableLanguages))
                        
                        let savedLocalization = try await self.localizationUseCase.loadPreferredLanguage(userId: userId)
                        let selectedCode = resolveLanguageCode(
                            savedLocalization?.languageCode,
                            availableLanguages: availableLanguages
                        )

                        if !selectedCode.isEmpty {
                            await MainActor.run {
                                LocalizationController.shared.apply(languageCode: selectedCode)
                            }
                        }
                        emitter.send(.setLanguage(selectedCode))
                    } catch {
                        logger.error("Language load failed: \(error)")
                    }
                }
            ]
            
        case let .setAvailableLanguages(languages):
            state.languages = languages
            if state.languageCode.isEmpty,
               let first = languages.first {
                state.languageCode = first.languageCode
            }
            return []
            
        case let .setLanguage(language):
            state.languageCode = language
            return []
            
        case let .saveLanguage(language):
            return [
                Effect { emitter in
                    do {
                        let userId = try await self.getCurrentUserId()
                        try await self.localizationUseCase.savePreferredLanguage(userId: userId, languageCode: language)
                        await MainActor.run {
                            LocalizationController.shared.apply(languageCode: language)
                        }
                        emitter.send(.setLanguage(language))
                    } catch {
                        logger.error("Language save failed: \(error)")
                    }
                }
            ]
            
        // Notification Settings
        case .loadNotificationSetting:
            return [
                Effect { emitter in
                    do {
                        let userId = try await self.getCurrentUserId()
                        if let preference = try await self.notificationUseCase.loadPreference(userId: userId) {
                            await self.notificationUseCase.updatePermissions(enabled: preference.isEnabled)
                            emitter.send(.setNotificationSetting(preference.isEnabled))
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
                Effect { emitter in
                    do {
                        let userId = try await self.getCurrentUserId()
                        try await self.notificationUseCase.updatePreference(userId: userId, isEnabled: enabled)
                        await self.notificationUseCase.updatePermissions(enabled: enabled)
                        emitter.send(.setNotificationSetting(enabled))
                    } catch {
                        logger.error("Notification setting save failed: \(error)")
                    }
                }
            ]
        case let .showToast(message):
            state.toastMessage = message
            return [
                .just(.toastStatus(false)),
                .just(.toastStatus(true))
            ]

        case let .toastStatus(status):
            state.toastIsPresented = status
            return []
        }
    }

    // MARK: - Helper
    private func resolveLanguageCode(
        _ savedCode: String?,
        availableLanguages: [LocalizationEntity]
    ) -> String {
        if let saved = savedCode {
            if availableLanguages.contains(where: { $0.languageCode == saved }) {
                return saved
            }
            return saved
        }
        return availableLanguages.first?.languageCode ?? ""
    }
}
