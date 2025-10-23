import Foundation
import Combine
import SwiftData
import SwiftDataCoreInterface
import AlarmDomainInterface
import MemoDomainInterface
import UserDomainInterface

public final class SwiftDataServiceImpl: SwiftDataService {

    private let context: ModelContext
    private let alarmsPublisher =  CurrentValueSubject<[AlarmEntity], Never>([])
    private let memosPublisher = CurrentValueSubject<[MemoEntity], Never>([])
    private var cancellables = Set<AnyCancellable>()
}
