import SwiftUI
import Rex
import RankFeatureInterface

public struct RankFactoryImpl: RankFactory {
    private let store: Store<RankReducer>
    
    public init(store: Store<RankReducer>) {
        self.store = store
    }

    public func makeInterface() -> RankInterface {
        return RankStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(RankView(interface: interface))
    }
}

public extension RankFactoryImpl {
    static func create() -> RankFactoryImpl {
        let store = Store<RankReducer>(
            initialState: RankState(),
            reducer: RankReducer()
        )
        return RankFactoryImpl(store: store)
    }
    
    static func create(initialState: RankState) -> RankFactoryImpl {
        let store = Store<RankReducer>(
            initialState: initialState,
            reducer: RankReducer()
        )
        return RankFactoryImpl(store: store)
    }
}
