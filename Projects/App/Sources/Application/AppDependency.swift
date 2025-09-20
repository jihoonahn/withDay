import Foundation
import Shared
import RootFeatureInterface
import RootFeature

public class AppDependencies {
    public static func setup() {
        let container = DIContainer.shared

        container.register(RootFactory.self) {
            return RootFactoryImpl.create()
        }
    }
}
