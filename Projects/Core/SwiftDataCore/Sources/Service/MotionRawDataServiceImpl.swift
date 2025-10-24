import Foundation
import SwiftData
import SwiftDataCoreInterface

@MainActor
public final class MotionRawDataServiceImpl: MotionRawDataService {
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func fetchMotionData(executionId: UUID) async throws -> [MotionRawDataModel] {
        let context = container.mainContext
        let descriptor = FetchDescriptor<MotionRawDataModel>(
            predicate: #Predicate { data in
                data.executionId == executionId
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return try context.fetch(descriptor)
    }
    
    public func saveMotionData(_ data: MotionRawDataModel) async throws {
        let context = container.mainContext
        context.insert(data)
        try context.save()
    }
}
