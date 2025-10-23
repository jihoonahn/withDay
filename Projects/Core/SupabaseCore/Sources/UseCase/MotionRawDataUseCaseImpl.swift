//
//  MotionRawDataUseCaseImpl.swift
//  SupabaseCore
//
//  Created by Jihoonahn on 10/23/25.
//  Copyright © 2025 me.jihoon. All rights reserved.
//

import Foundation
import MotionRawDataDomainInterface

public final class MotionRawDataUseCaseImpl: MotionRawDataUseCase {
    private let motionRawDataRepository: MotionRawDataRepository
    
    public init(motionRawDataRepository: MotionRawDataRepository) {
        self.motionRawDataRepository = motionRawDataRepository
    }
    
    public func fetchAll(executionId: UUID) async throws -> [MotionRawDataEntity] {
        return try await motionRawDataRepository.fetchAll(executionId: executionId)
    }
    
    public func create(_ data: MotionRawDataEntity) async throws {
        try await motionRawDataRepository.create(data)
    }
}
