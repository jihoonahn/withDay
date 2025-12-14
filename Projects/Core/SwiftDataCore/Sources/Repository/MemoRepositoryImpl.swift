import Foundation
import MemosDomainInterface
import SwiftDataCoreInterface

public final class MemoRepositoryImpl: MemosRepository {
    
    private let memoService: SwiftDataCoreInterface.MemosService
    
    public init(memoService: SwiftDataCoreInterface.MemosService) {
        self.memoService = memoService
    }

    public func createMemo(_ memo: MemosEntity) async throws {
        let model = MemosDTO.toModel(from: memo)
        try await memoService.createMemo(model)
    }
    
    public func updateMemo(_ memo: MemosEntity) async throws {
        let model = MemosDTO.toModel(from: memo)
        try await memoService.updateMemo(model)
    }
    
    public func deleteMemo(id: UUID) async throws {
        try await memoService.deleteMemo(id: id)
    }
    
    public func fetchMemo(id: UUID) async throws -> MemosEntity {
        let model = try await memoService.getMemo(id: id)
        return MemosDTO.toEntity(from: model)
    }
    
    public func fetchMemos(userId: UUID) async throws -> [MemosEntity] {
        let models = try await memoService.getMemos(userId: userId)
        return models.map { MemosDTO.toEntity(from: $0) }
    }
    
    public func searchMemos(userId: UUID, keyword: String) async throws -> [MemosEntity] {
        let models = try await memoService.searchMemos(userId: userId, keyword: keyword)
        return models.map { MemosDTO.toEntity(from: $0) }
    }
    
    public func fetchMemosByAlarmId(alarmId: UUID) async throws -> [MemosEntity] {
        let models = try await memoService.getMemosByAlarmId(alarmId: alarmId)
        return models.map { MemosDTO.toEntity(from: $0) }
    }
    
    public func fetchMemosByScheduleId(scheduleId: UUID) async throws -> [MemosEntity] {
        let models = try await memoService.getMemosByScheduleId(scheduleId: scheduleId)
        return models.map { MemosDTO.toEntity(from: $0) }
    }
}
