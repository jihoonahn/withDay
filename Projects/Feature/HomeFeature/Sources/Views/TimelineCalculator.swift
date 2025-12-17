import Foundation
import SwiftUI

// MARK: - Timeline Calculator
struct TimelineCalculator {
    // MARK: - Constants
    enum Constants {
        static let defaultAlarmDuration: Int = 30 // 알람 기본 지속 시간 (분)
        static let pixelsPerHour: CGFloat = 40 // 시간당 픽셀 수
        static let baseTimelineHeight: CGFloat = 24 * 40 // 24시간 * 40픽셀 = 960픽셀
        static let dividerHeight: CGFloat = 20 // 12시 구분선 높이
        static let pixelsPerMinute: CGFloat = pixelsPerHour / 60.0 // 분당 픽셀 수
    }
    
    // MARK: - Data Structures
    struct TimelineData {
        let morningHeight: CGFloat // 오전 구간 높이 (12시간 * 40픽셀)
        let afternoonHeight: CGFloat // 오후 구간 높이 (12시간 * 40픽셀)
        let totalHeight: CGFloat // 전체 높이 (아이템 확장 포함)
    }
    
    struct ItemPosition {
        let y: CGFloat
        let pixelsPerMinute: CGFloat
    }
    
    // MARK: - Timeline Data Calculation
    static func calculateTimelineData(
        for items: [any TimelineItemProtocol],
        memoCounts: [UUID: Int]
    ) -> TimelineData {
        // 기본 타임라인 높이: 각 구간 12시간 * 40픽셀 = 480픽셀
        let baseMorningHeight: CGFloat = 12 * Constants.pixelsPerHour // 480픽셀
        let baseAfternoonHeight: CGFloat = 12 * Constants.pixelsPerHour // 480픽셀
        
        // 빈 배열 처리
        guard !items.isEmpty else {
            let bottomPadding: CGFloat = 100
            return TimelineData(
                morningHeight: baseMorningHeight,
                afternoonHeight: baseAfternoonHeight,
                totalHeight: baseMorningHeight + baseAfternoonHeight + Constants.dividerHeight + bottomPadding
            )
        }
        
        // 오전(0-720분)과 오후(720-1440분) 아이템 분리
        let morningItems = items.filter { $0.timeValue < 720 }
        let afternoonItems = items.filter { $0.timeValue >= 720 }
        
        // 오전 구간 높이 계산
        let calculatedMorningHeight = calculatePeriodHeight(
            items: morningItems,
            memoCounts: memoCounts,
            baseHeight: baseMorningHeight,
            startOffset: 0
        )
        
        // 오후 구간 높이 계산
        let calculatedAfternoonHeight = calculatePeriodHeight(
            items: afternoonItems,
            memoCounts: memoCounts,
            baseHeight: baseAfternoonHeight,
            startOffset: calculatedMorningHeight
        )
        
        // 전체 높이 = 오전 + 구분선 + 오후 + 하단 여백
        let bottomPadding: CGFloat = 100
        let totalHeight = calculatedMorningHeight + Constants.dividerHeight + calculatedAfternoonHeight + bottomPadding
        
        return TimelineData(
            morningHeight: calculatedMorningHeight,
            afternoonHeight: calculatedAfternoonHeight,
            totalHeight: totalHeight
        )
    }
    
    // MARK: - Period Height Calculation
    private static func calculatePeriodHeight(
        items: [any TimelineItemProtocol],
        memoCounts: [UUID: Int],
        baseHeight: CGFloat,
        startOffset: CGFloat
    ) -> CGFloat {
        // 아이템이 없으면 기본 높이 반환
        guard !items.isEmpty else {
            return baseHeight
        }
        
        var lastItemEndY: CGFloat = 0
        var lastItemTimeValue: Int? = nil
        
        for item in items {
            let endTime = min(item.endTimeValue ?? item.timeValue, 1440)
            let duration = max(0, endTime - item.timeValue)
            
            // 아이템의 기본 높이 (시간 기반)
            let itemTimeHeight = CGFloat(duration) * Constants.pixelsPerMinute
            
            // 메모 높이 추가
            let memoCount = memoCounts[item.id] ?? 0
            let memoHeight = calculateMemoHeight(memoCount: memoCount)
            
            let itemHeight = max(100, itemTimeHeight) + memoHeight
            
            // 아이템의 시작 Y 위치 (시간 기반) - 구간 시작점 기준
            let itemStartY = CGFloat(item.timeValue) * Constants.pixelsPerMinute
            
            // 간격 계산 (시간 차이에 비례)
            let spacing = calculateSpacing(
                currentTime: item.timeValue,
                lastTime: lastItemTimeValue
            )
            
            // 실제 배치될 Y 위치
            let actualY = calculateItemYPosition(
                itemStartY: itemStartY,
                lastItemEndY: lastItemEndY,
                spacing: spacing,
                timeDifference: lastItemTimeValue.map { abs(item.timeValue - $0) }
            )
            let actualEndY = actualY + itemHeight
            
            lastItemEndY = actualEndY
            lastItemTimeValue = item.timeValue
        }
        
        // 구간 높이 = max(기본 높이, 마지막 아이템 끝 위치)
        let periodHeight = max(baseHeight, lastItemEndY)
        
        return periodHeight.isFinite && periodHeight > 0 ? periodHeight : baseHeight
    }
    
    // MARK: - Item Position Calculation
    static func calculateItemPositions(
        items: [any TimelineItemProtocol],
        timelineData: TimelineData,
        memoCounts: [UUID: Int]
    ) -> [ItemPosition] {
        // 빈 배열 처리
        guard !items.isEmpty else {
            return []
        }
        
        // 오전/오후 아이템 분리
        let morningItems = items.filter { $0.timeValue < 720 }
        let afternoonItems = items.filter { $0.timeValue >= 720 }
        
        var positions: [ItemPosition] = []
        
        // 오전 아이템 위치 계산
        let morningPositions = calculatePeriodPositions(
            items: morningItems,
            memoCounts: memoCounts,
            offsetY: 0
        )
        
        // 오후 아이템 위치 계산 (오전 높이 + 구분선만큼 오프셋)
        let afternoonOffset = timelineData.morningHeight + Constants.dividerHeight
        let afternoonPositions = calculatePeriodPositions(
            items: afternoonItems,
            memoCounts: memoCounts,
            offsetY: afternoonOffset
        )
        
        // 원래 items 순서대로 positions 재구성
        for item in items {
            if item.timeValue < 720 {
                // 오전 아이템
                if let index = morningItems.firstIndex(where: { $0.id == item.id }) {
                    positions.append(morningPositions[index])
                }
            } else {
                // 오후 아이템
                if let index = afternoonItems.firstIndex(where: { $0.id == item.id }) {
                    positions.append(afternoonPositions[index])
                }
            }
        }
        
        // items와 positions의 길이가 반드시 일치해야 함
        guard positions.count == items.count else {
            return []
        }
        
        return positions
    }
    
    // MARK: - Period Position Calculation
    private static func calculatePeriodPositions(
        items: [any TimelineItemProtocol],
        memoCounts: [UUID: Int],
        offsetY: CGFloat
    ) -> [ItemPosition] {
        guard !items.isEmpty else {
            return []
        }
        
        var positions: [ItemPosition] = []
        var lastEndY: CGFloat = -1000
        var lastItemTimeValue: Int? = nil
        
        for item in items {
            // 기본 Y 위치: 시간 기반
            let baseY = CGFloat(item.timeValue) * Constants.pixelsPerMinute
            
            // 안전한 Y 위치 계산
            let safeBaseY = baseY.isFinite ? baseY : 0
            let safeLastEndY = lastEndY.isFinite ? lastEndY : -1000
            
            // 아이템 간 간격 계산
            let spacing = calculateSpacing(
                currentTime: item.timeValue,
                lastTime: lastItemTimeValue
            )
            
            // 이전 아이템과 겹치지 않도록 위치 계산
            let finalY = calculateItemYPosition(
                itemStartY: safeBaseY,
                lastItemEndY: safeLastEndY,
                spacing: spacing,
                timeDifference: lastItemTimeValue.map { abs(item.timeValue - $0) }
            )
            
            // 아이템 높이 계산
            let endTime = min(item.endTimeValue ?? item.timeValue, 1440)
            let duration = max(0, endTime - item.timeValue)
            let timeHeight = CGFloat(duration) * Constants.pixelsPerMinute
            
            // 메모 높이 추가
            let memoCount = memoCounts[item.id] ?? 0
            let memoHeight = calculateMemoHeight(memoCount: memoCount)
            
            // 기본 아이템 높이 + 메모 높이
            let itemHeight = max(100, timeHeight) + memoHeight
            
            // 마지막 끝 위치 업데이트
            let safeFinalY = finalY.isFinite ? finalY : 0
            let safeItemHeight = itemHeight.isFinite ? itemHeight : 100
            lastEndY = safeFinalY + safeItemHeight
            lastItemTimeValue = item.timeValue
            
            // offsetY를 더해서 최종 위치 결정
            positions.append(ItemPosition(y: safeFinalY + offsetY, pixelsPerMinute: Constants.pixelsPerMinute))
        }
        
        return positions
    }
    
    // MARK: - Helper Methods
    private static func calculateSpacing(
        currentTime: Int,
        lastTime: Int?
    ) -> CGFloat {
        guard let lastTime = lastTime else {
            return 10 // 첫 번째 아이템
        }
        
        let timeDifferenceMinutes = abs(currentTime - lastTime)
        if timeDifferenceMinutes <= 5 {
            // 5분 이내: 최소 간격 5픽셀
            return 5
        } else {
            // 5분 이상: 시간 차이에 비례하여 간격 계산
            let proportionalSpacing = CGFloat(timeDifferenceMinutes) * Constants.pixelsPerMinute
            return max(10, proportionalSpacing)
        }
    }
    
    private static func calculateItemYPosition(
        itemStartY: CGFloat,
        lastItemEndY: CGFloat,
        spacing: CGFloat,
        timeDifference: Int?
    ) -> CGFloat {
        guard let timeDifference = timeDifference, timeDifference <= 5 else {
            // 5분 이상: 시간 기반 위치와 이전 아이템 끝 위치 중 큰 값 사용
            return max(itemStartY, lastItemEndY + spacing)
        }
        
        // 5분 이내: 이전 아이템의 끝 위치(메모 포함) 바로 다음에 배치
        return lastItemEndY + spacing
    }
    
    private static func calculateMemoHeight(memoCount: Int) -> CGFloat {
        guard memoCount > 0 else {
            return 0.0
        }
        
        // 메모 섹션 상단 여백(12) + 메모 카드들(평균 90픽셀) + 메모 카드 간 간격(8 * (개수-1))
        return 12.0 + CGFloat(memoCount) * 90.0 + CGFloat(max(0, memoCount - 1)) * 8.0
    }
}

// MARK: - TimelineItem Protocol
protocol TimelineItemProtocol {
    var id: UUID { get }
    var timeValue: Int { get }
    var endTimeValue: Int? { get }
}

