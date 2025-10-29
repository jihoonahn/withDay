import SwiftUI
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface
import UserDomainInterface
import SwiftDataCoreInterface

public struct AlarmFactoryImpl: AlarmFactory {
    private let store: Store<AlarmReducer>
    private let remoteRepository: AlarmRepository
    
    public init(store: Store<AlarmReducer>, remoteRepository: AlarmRepository) {
        self.store = store
        self.remoteRepository = remoteRepository
    }

    public func makeInterface() -> AlarmInterface {
        return AlarmStore(store: store, remoteRepository: remoteRepository)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(AlarmView(interface: interface))
    }
}

public extension AlarmFactoryImpl {
    static func create(
        remoteRepository: AlarmRepository,
        localService: SwiftDataCoreInterface.AlarmService?,
        userUseCase: UserUseCase
    ) -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: AlarmState(),
            reducer: AlarmReducer(
                remoteRepository: remoteRepository,
                localService: localService,
                userUseCase: userUseCase
            )
        )
        return AlarmFactoryImpl(store: store, remoteRepository: remoteRepository)
    }
    
    static func create(
        initialState: AlarmState,
        remoteRepository: AlarmRepository,
        localService: SwiftDataCoreInterface.AlarmService?,
        userUseCase: UserUseCase
    ) -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: initialState,
            reducer: AlarmReducer(
                remoteRepository: remoteRepository,
                localService: localService,
                userUseCase: userUseCase
            )
        )
        return AlarmFactoryImpl(store: store, remoteRepository: remoteRepository)
    }
}
