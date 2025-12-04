import SwiftUI
import Rex
import MemoFeatureInterface
import MemoDomainInterface
import UserDomainInterface
import AlarmExecutionDomainInterface
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
        memoUseCase: MemoUseCase,
        userUseCase: UserUseCase
    ) -> MemoFactoryImpl {
        let store = Store<MemoReducer>(
            initialState: MemoState(),
            reducer: MemoReducer(
                memoUseCase: memoUseCase,
                userUseCase: userUseCase
            )
        )
        return MemoFactoryImpl(store: store)
    }
    
    static func create(
        initialState: MemoState,
        memoUseCase: MemoUseCase,
        userUseCase: UserUseCase
    ) -> MemoFactoryImpl {
        let store = Store<MemoReducer>(
            initialState: initialState,
            reducer: MemoReducer(
                memoUseCase: memoUseCase,
                userUseCase: userUseCase
            )
        )
        return MemoFactoryImpl(store: store)
    }
}
