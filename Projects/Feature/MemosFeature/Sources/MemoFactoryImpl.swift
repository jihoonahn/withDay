import SwiftUI
import Rex
import MemosFeatureInterface
import MemosDomainInterface
import UsersDomainInterface
import AlarmExecutionsDomainInterface
import Dependency

public struct MemoFactoryImpl: MemoFactory {
    private let store: Store<MemoReducer>
    
    public init(store: Store<MemoReducer>) {
        self.store = store
    }

    public func makeInterface() -> MemoInterface {
        return MemoStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(MemoView(interface: interface))
    }
}

public extension MemoFactoryImpl {
    static func create(
        memosUseCase: MemosUseCase,
        usersUseCase: UsersUseCase
    ) -> MemoFactoryImpl {
        let store = Store<MemoReducer>(
            initialState: MemoState(),
            reducer: MemoReducer(
                memosUseCase: memosUseCase,
                usersUseCase: usersUseCase
            )
        )
        return MemoFactoryImpl(store: store)
    }
    
    static func create(
        initialState: MemoState,
        memosUseCase: MemosUseCase,
        usersUseCase: UsersUseCase
    ) -> MemoFactoryImpl {
        let store = Store<MemoReducer>(
            initialState: initialState,
            reducer: MemoReducer(
                memosUseCase: memosUseCase,
                usersUseCase: usersUseCase
            )
        )
        return MemoFactoryImpl(store: store)
    }
}
