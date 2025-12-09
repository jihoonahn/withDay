import SwiftUI
import Rex
import SettingsFeatureInterface
import UsersDomainInterface
import LocalizationDomainInterface
import NotificationDomainInterface

public struct SettingFactoryImpl: SettingFactory {
    private let store: Store<SettingReducer>
    
    public init(store: Store<SettingReducer>) {
        self.store = store
    }

    public func makeInterface() -> SettingInterface {
        return SettingStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(SettingView(interface: interface))
    }
}

public extension SettingFactoryImpl {
    static func create(
        usersUseCase: UsersUseCase,
        localizationUseCase: LocalizationUseCase,
        notificationUseCase: NotificationUseCase
    ) -> SettingFactoryImpl {
        let store = Store<SettingReducer>(
            initialState: SettingState(),
            reducer: SettingReducer(
                usersUseCase: usersUseCase,
                localizationUseCase: localizationUseCase,
                notificationUseCase: notificationUseCase
            )
        )
        return SettingFactoryImpl(store: store)
    }
    
    static func create(
        initialState: SettingState,
        usersUseCase: UsersUseCase,
        localizationUseCase: LocalizationUseCase,
        notificationUseCase: NotificationUseCase
    ) -> SettingFactoryImpl {
        let store = Store<SettingReducer>(
            initialState: initialState,
            reducer: SettingReducer(
                usersUseCase: usersUseCase,
                localizationUseCase: localizationUseCase,
                notificationUseCase: notificationUseCase,
            )
        )
        return SettingFactoryImpl(store: store)
    }
}
