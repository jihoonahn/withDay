import SwiftUI
import Rex
import SettingFeatureInterface
import UserDomainInterface
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
        userUseCase: UserUseCase,
        localizationUseCase: LocalizationUseCase,
        notificationUseCase: NotificationUseCase
    ) -> SettingFactoryImpl {
        let store = Store<SettingReducer>(
            initialState: SettingState(),
            reducer: SettingReducer(
                userUseCase: userUseCase,
                localizationUseCase: localizationUseCase,
                notificationUseCase: notificationUseCase
            )
        )
        return SettingFactoryImpl(store: store)
    }
    
    static func create(
        initialState: SettingState,
        userUseCase: UserUseCase,
        localizationUseCase: LocalizationUseCase,
        notificationUseCase: NotificationUseCase
    ) -> SettingFactoryImpl {
        let store = Store<SettingReducer>(
            initialState: initialState,
            reducer: SettingReducer(
                userUseCase: userUseCase,
                localizationUseCase: localizationUseCase,
                notificationUseCase: notificationUseCase
            )
        )
        return SettingFactoryImpl(store: store)
    }
}
