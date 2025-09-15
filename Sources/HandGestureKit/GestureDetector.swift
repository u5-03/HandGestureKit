//
//  GestureDetector.swift
//  HandGesturePackage
//
//  Created by Yugo Sugiyama on 2025/07/26.
//

import ARKit
import Foundation
import HandGestureKit
import RealityKit

/// Integrated gesture detection system
/// Unifies detection of single-hand and two-hand gestures
public class GestureDetector {

    // MARK: - Properties

    /// Registered gestures (sorted by priority)
    private var sortedGestures: [BaseGestureProtocol] = []


    /// Index by gesture type
    private var typeIndex: [GestureType: [Int]] = [:]

    /// Search statistics
    public private(set) var searchStats = SearchStats()

    // MARK: - Initialization

    public init(gestures: [BaseGestureProtocol] = []) {
        registerGestures(gestures)
    }

    // MARK: - Registration

    /// Register gestures
    public func registerGestures(_ gestures: [BaseGestureProtocol]) {
        // Sort by priority
        sortedGestures = gestures.sorted { $0.priority < $1.priority }

        // Build indices
        buildIndices()

        HandGestureLogger.logGesture("🎯 UnifiedGestureDetector: Registered \(gestures.count) gestures")
        logGestureInfo()
    }

    /// Add gesture
    public func addGesture(_ gesture: BaseGestureProtocol) {
        sortedGestures.append(gesture)
        registerGestures(sortedGestures)
    }

    // MARK: - Detection Methods

    /// Detect gestures from HandTrackingComponent array
    public func detectGestures(
        from handEntities: [Entity],
        targetGestures: [BaseGestureProtocol]? = nil
    ) -> GestureDetectionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        searchStats.searchCount += 1

        // Extract HandTrackingComponent from entities
        var leftHandComponent: HandTrackingComponent?
        var rightHandComponent: HandTrackingComponent?

        for entity in handEntities {
            guard let handComponent = entity.components[HandTrackingComponent.self] else {
                continue
            }

            // Check if hand data is valid
            if let wrist = handComponent.fingers[.wrist] {
                let wristPos = wrist.position(relativeTo: nil)
                if wristPos.x == 0 && wristPos.y == 0 && wristPos.z == 0 {
                    continue
                }
            }

            if handComponent.chirality == .left {
                leftHandComponent = handComponent
            } else {
                rightHandComponent = handComponent
            }
        }

        // When there is no hand data
        guard leftHandComponent != nil || rightHandComponent != nil else {
            return .failure(.noHandDataAvailable)
        }

        // Create gesture data
        let leftGestureData = leftHandComponent.map {
            SingleHandGestureData(handTrackingComponent: $0, handKind: .left)
        }
        let rightGestureData = rightHandComponent.map {
            SingleHandGestureData(handTrackingComponent: $0, handKind: .right)
        }

        let handsGestureData: HandsGestureData?
        if let left = leftGestureData, let right = rightGestureData {
            handsGestureData = HandsGestureData(leftHand: left, rightHand: right)
        } else {
            handsGestureData = nil
        }

        // Execute detection
        let gesturesToCheck = targetGestures ?? sortedGestures
        var detectedGestures: [DetectedGesture] = []

        for gesture in gesturesToCheck {
            searchStats.gesturesChecked += 1

            let matches: Bool
            let confidence: Float = 1.0
            var metadata: [String: Any] = [:]

            switch gesture.gestureType {
            case .singleHand:
                if let singleGesture = gesture as? SingleHandGestureProtocol {
                    // Check if either left or right hand matches
                    let leftMatches = leftGestureData.map { singleGesture.matches($0) } ?? false
                    let rightMatches = rightGestureData.map { singleGesture.matches($0) } ?? false

                    // When left hand matches
                    if leftMatches {
                        var leftMetadata = metadata
                        leftMetadata["detectedHand"] = "left"
                        detectedGestures.append(
                            DetectedGesture(
                                gesture: gesture,
                                confidence: confidence,
                                metadata: leftMetadata
                            ))
                        searchStats.matchesFound += 1
                    }

                    // When right hand matches
                    if rightMatches {
                        var rightMetadata = metadata
                        rightMetadata["detectedHand"] = "right"
                        detectedGestures.append(
                            DetectedGesture(
                                gesture: gesture,
                                confidence: confidence,
                                metadata: rightMetadata
                            ))
                        searchStats.matchesFound += 1
                    }

                    // Flag for when neither hand matches
                    matches = false  // To skip in subsequent processing
                } else {
                    matches = false
                }

            case .twoHand:
                if let twoHandGesture = gesture as? TwoHandsGestureProtocol,
                    let hands = handsGestureData
                {
                    matches = twoHandGesture.matches(hands)

                    if matches {
                        metadata["palmDistance"] = hands.palmCenterDistance
                        metadata["areFacingEachOther"] = hands.arePalmsFacingEachOther
                    }
                } else {
                    matches = false
                }
            }

            // Single-hand gestures have already been added individually, so only add other gestures
            if matches && gesture.gestureType != .singleHand {
                detectedGestures.append(
                    DetectedGesture(
                        gesture: gesture,
                        confidence: confidence,
                        metadata: metadata
                    ))
                searchStats.matchesFound += 1
            }
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        searchStats.totalSearchTime += (endTime - startTime)

        return .success(detectedGestures)
    }


    // MARK: - Utility Methods

    /// Reset search statistics
    public func resetSearchStats() {
        searchStats = SearchStats()
    }

    /// Get information about registered gestures
    public func getRegisteredGesturesInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        info["totalGestures"] = sortedGestures.count

        // Count by type
        var typeCount: [String: Int] = [:]
        typeCount["singleHand"] = typeIndex[.singleHand]?.count ?? 0
        typeCount["twoHand"] = typeIndex[.twoHand]?.count ?? 0
        info["typeCounts"] = typeCount

        return info
    }

    // MARK: - Private Methods

    /// Build indices
    private func buildIndices() {
        typeIndex.removeAll()

        for (index, gesture) in sortedGestures.enumerated() {
            // Type index
            if typeIndex[gesture.gestureType] == nil {
                typeIndex[gesture.gestureType] = []
            }
            typeIndex[gesture.gestureType]?.append(index)
        }
    }


    /// Log gesture information
    private func logGestureInfo() {
        // By type
        HandGestureLogger.logDebug("  🤚 Single hand: \(typeIndex[.singleHand]?.count ?? 0) gestures")
        HandGestureLogger.logDebug("  🙌 Two hands: \(typeIndex[.twoHand]?.count ?? 0) gestures")
    }

    /// Serial gesture detection (stateless)
    /// - Parameters:
    ///   - handEntities: Array of hand entities
    ///   - serialGesture: Serial gesture to detect
    ///   - currentIndex: Index of the gesture currently being checked
    /// - Returns: Serial gesture detection result
    public func detectSerialGesture(
        from handEntities: [Entity],
        serialGesture: SerialGestureProtocol,
        currentIndex: Int
    ) -> SerialGestureDetectionResult {
        // Index validity check
        guard currentIndex >= 0 && currentIndex < serialGesture.gestures.count else {
            return .notMatched
        }

        // Get the gesture for the current step
        let currentGesture = serialGesture.gestures[currentIndex]

        HandGestureLogger.logDebug(
            "🔍 Serial gesture detection: \(serialGesture.gestureName) - Step \(currentIndex)/\(serialGesture.gestures.count - 1)"
        )

        // Use existing detectGestures method for detection
        let result = detectGestures(from: handEntities, targetGestures: [currentGesture])

        switch result {
        case .success(let detectedGestures):
            if !detectedGestures.isEmpty {
                // Current gesture matched
                if currentIndex == serialGesture.gestures.count - 1 {
                    // All gestures completed
                    HandGestureLogger.logDebug("🎉 Serial gesture completed: \(serialGesture.gestureName)")
                    return .completed(gesture: serialGesture)
                } else {
                    // More steps remaining
                    HandGestureLogger.logDebug("➡️ Proceeding to next step: \(currentIndex + 1)")
                    return .progress(
                        currentIndex: currentIndex + 1,
                        totalGestures: serialGesture.gestures.count,
                        gesture: serialGesture
                    )
                }
            } else {
                // Current gesture did not match
                return .notMatched
            }
        case .failure:
            // Treat errors as non-matches
            return .notMatched
        }
    }
}

// MARK: - Convenience Extensions

extension GestureDetector {

    /// Detect only high-priority gestures
    public func detectHighPriorityGestures(
        from handEntities: [Entity],
        priorityThreshold: Int = 100
    ) -> GestureDetectionResult {
        let highPriorityGestures = sortedGestures.filter { $0.priority <= priorityThreshold }
        return detectGestures(from: handEntities, targetGestures: highPriorityGestures)
    }
}
