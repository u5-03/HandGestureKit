//
//  SingleHandGestureProtocol.swift
//  HandGestureKit
//
//  Created by Yugo Sugiyama on 2025/07/30.
//

import Foundation

/// Protocol defining conditions for single hand gestures
/// Each gesture implements this protocol and defines only the necessary conditions
public protocol SingleHandGestureProtocol: BaseGestureProtocol {

    // MARK: - Gesture Matching

    /// Determines if the specified SingleHandGestureData meets this gesture's conditions
    /// - Parameter gestureData: Hand data to evaluate
    /// - Returns: true if conditions are met
    func matches(_ gestureData: SingleHandGestureData) -> Bool

    // MARK: - Finger State Determination Functions

    /// Determines if the specified fingers need to be straight
    /// - Parameter fingers: Array of fingers to check
    /// - Returns: true if the specified fingers need to be straight
    func requiresFingersStraight(_ fingers: [FingerType]) -> Bool

    /// Determines if the specified fingers need to be bent
    /// - Parameter fingers: Array of fingers to check
    /// - Returns: true if the specified fingers need to be bent
    func requiresFingersBent(_ fingers: [FingerType]) -> Bool

    /// Determines if the specified finger needs to be pointing in a specific direction
    /// - Parameters:
    ///   - finger: The finger to check
    ///   - direction: The expected direction
    /// - Returns: true if the specified finger needs to be pointing in the specific direction
    func requiresFingerPointing(_ finger: FingerType, direction: GestureDetectionDirection) -> Bool

    // MARK: - Palm Direction Determination Functions

    /// Determines if the palm needs to be facing a specific direction
    /// - Parameter direction: The expected direction
    /// - Returns: true if the palm needs to be facing the specific direction
    func requiresPalmFacing(_ direction: GestureDetectionDirection) -> Bool

    // MARK: - Arm Direction Determination Functions

    /// Determines if the arm needs to be extended in a specific direction
    /// - Parameter direction: The expected direction
    /// - Returns: true if the arm needs to be extended in the specific direction
    func requiresArmExtendedInDirection(_ direction: GestureDetectionDirection) -> Bool

    // MARK: - Complex Finger Conditions (Convenience Properties)

    /// Whether all fingers need to be bent (fist state)
    var requiresAllFingersBent: Bool { get }

    /// Whether only the index finger needs to be straight
    var requiresOnlyIndexFingerStraight: Bool { get }

    /// Whether only the index and middle fingers need to be straight (peace sign, etc.)
    var requiresOnlyIndexAndMiddleStraight: Bool { get }

    /// Whether only the thumb needs to be straight
    var requiresOnlyThumbStraight: Bool { get }

    /// Whether only the little finger needs to be straight
    var requiresOnlyLittleFingerStraight: Bool { get }

    // MARK: - Wrist State Conditions

    /// Whether the wrist needs to be bent outward (back side)
    var requiresWristBentOutward: Bool { get }

    /// Whether the wrist needs to be bent inward (palm side)
    var requiresWristBentInward: Bool { get }

    /// Whether the wrist needs to be straight
    var requiresWristStraight: Bool { get }

    // MARK: - Arm State Conditions

    /// Whether the arm needs to be extended
    var requiresArmExtended: Bool { get }
}

/// Default implementation: All conditions set to false
/// Each gesture overrides only the necessary conditions
extension SingleHandGestureProtocol {

    // MARK: - Default Identification Information

    /// Default priority (low priority)
    public var priority: Int { 1000 }


    /// Default gesture type
    public var gestureType: GestureType { .singleHand }

    // MARK: - Default Matching Implementation

    /// Default matching implementation: Check all conditions
    public func matches(_ gestureData: SingleHandGestureData) -> Bool {
        // Early return: Basic condition checks

        // 1. Complex finger condition checks
        if requiresAllFingersBent && !areAllFingersBent(gestureData) {
            return false
        }

        if requiresOnlyIndexFingerStraight && !isOnlyIndexFingerStraight(gestureData) {
            return false
        }

        if requiresOnlyIndexAndMiddleStraight && !isOnlyIndexAndMiddleStraight(gestureData) {
            return false
        }

        if requiresOnlyThumbStraight && !isOnlyThumbStraight(gestureData) {
            return false
        }

        if requiresOnlyLittleFingerStraight && !isOnlyLittleFingerStraight(gestureData) {
            return false
        }

        // 2. Wrist state checks
        if requiresWristBentOutward && !gestureData.isWristBentOutward {
            return false
        }

        if requiresWristBentInward && !gestureData.isWristBentInward {
            return false
        }

        if requiresWristStraight && !gestureData.isWristStraight {
            return false
        }

        // 3. Arm state checks
        if requiresArmExtended && !gestureData.armExtended {
            return false
        }

        // 4. Individual finger state checks (check all FingerType)
        for finger in FingerType.allCases {
            // Finger extension state check
            if requiresFingersStraight([finger]) && !gestureData.isFingerStraight(finger) {
                return false
            }

            if requiresFingersBent([finger]) && !gestureData.isFingerBent(finger) {
                return false
            }

            // Finger direction check (test all directions)
            for direction in GestureDetectionDirection.allCases {
                if requiresFingerPointing(finger, direction: direction)
                    && !gestureData.isFingerPointing(finger, direction: direction)
                {
                    return false
                }
            }
        }

        // 5. Palm direction checks
        for direction in GestureDetectionDirection.allCases {
            if requiresPalmFacing(direction) && !gestureData.isPalmFacing(direction) {
                return false
            }
        }

        // 6. Arm direction checks
        for direction in GestureDetectionDirection.allCases {
            if requiresArmExtendedInDirection(direction)
                && !gestureData.isArmExtendedInDirection(direction)
            {
                return false
            }
        }

        return true
    }

    // MARK: - Finger State Determination Functions (Default Implementation)

    /// Whether the specified fingers need to be straight (default: not required)
    public func requiresFingersStraight(_ fingers: [FingerType]) -> Bool {
        return false
    }

    /// Whether the specified fingers need to be bent (default: not required)
    public func requiresFingersBent(_ fingers: [FingerType]) -> Bool {
        return false
    }

    /// Whether the specified finger needs to be pointing in a specific direction (default: not required)
    public func requiresFingerPointing(_ finger: FingerType, direction: GestureDetectionDirection)
        -> Bool
    {
        return false
    }

    // MARK: - Palm Direction Determination Functions (Default Implementation)

    /// Whether the palm needs to be facing a specific direction (default: not required)
    public func requiresPalmFacing(_ direction: GestureDetectionDirection) -> Bool {
        return false
    }

    // MARK: - Arm Direction Determination Functions (Default Implementation)

    /// Whether the arm needs to be extended in a specific direction (default: not required)
    public func requiresArmExtendedInDirection(_ direction: GestureDetectionDirection) -> Bool {
        return false
    }

    // MARK: - Complex Finger Conditions (Default Values)

    public var requiresAllFingersBent: Bool { false }
    public var requiresOnlyIndexFingerStraight: Bool { false }
    public var requiresOnlyIndexAndMiddleStraight: Bool { false }
    public var requiresOnlyThumbStraight: Bool { false }
    public var requiresOnlyLittleFingerStraight: Bool { false }

    // MARK: - Wrist State Conditions (Default Values)

    public var requiresWristBentOutward: Bool { false }
    public var requiresWristBentInward: Bool { false }
    public var requiresWristStraight: Bool { false }

    // MARK: - Arm State Conditions (Default Values)

    public var requiresArmExtended: Bool { false }

    // MARK: - Helper Methods (Default Implementation)

    /// Determines if all fingers are bent
    private func areAllFingersBent(_ gestureData: SingleHandGestureData) -> Bool {
        return FingerType.allCases.allSatisfy { gestureData.isFingerBent($0) }
    }

    /// Determines if only the index finger is straight
    private func isOnlyIndexFingerStraight(_ gestureData: SingleHandGestureData) -> Bool {
        return gestureData.isFingerStraight(.index) && gestureData.isFingerBent(.thumb)
            && gestureData.isFingerBent(.middle) && gestureData.isFingerBent(.ring)
            && gestureData.isFingerBent(.little)
    }

    /// Determines if only the index and middle fingers are straight
    private func isOnlyIndexAndMiddleStraight(_ gestureData: SingleHandGestureData) -> Bool {
        return gestureData.isFingerStraight(.index) && gestureData.isFingerStraight(.middle)
            && gestureData.isFingerBent(.thumb) && gestureData.isFingerBent(.ring)
            && gestureData.isFingerBent(.little)
    }

    /// Determines if only the thumb is straight
    private func isOnlyThumbStraight(_ gestureData: SingleHandGestureData) -> Bool {
        return gestureData.isFingerStraight(.thumb) && gestureData.isFingerBent(.index)
            && gestureData.isFingerBent(.middle) && gestureData.isFingerBent(.ring)
            && gestureData.isFingerBent(.little)
    }

    /// Determines if only the little finger is straight
    private func isOnlyLittleFingerStraight(_ gestureData: SingleHandGestureData) -> Bool {
        return gestureData.isFingerStraight(.little) && gestureData.isFingerBent(.thumb)
            && gestureData.isFingerBent(.index) && gestureData.isFingerBent(.middle)
            && gestureData.isFingerBent(.ring)
    }
}

// MARK: - Advanced Protocol Extensions

extension SingleHandGestureProtocol {

    // MARK: - Performance Optimized Matching

    /// Fast validation of multiple conditions (early return optimization)
    /// - Parameter gestureData: Gesture data to validate
    /// - Returns: true if all conditions are met
    public func matchesWithOptimization(_ gestureData: SingleHandGestureData) -> Bool {
        // 1. Most selective conditions first (finger configuration)
        if requiresOnlyIndexAndMiddleStraight {
            guard
                GestureValidation.validateOnlyTargetFingersStraight(
                    gestureData,
                    targetFingers: [.index, .middle]
                )
            else { return false }
        }

        if requiresOnlyIndexFingerStraight {
            guard
                GestureValidation.validateOnlyTargetFingersStraight(
                    gestureData,
                    targetFingers: [.index]
                )
            else { return false }
        }

        if requiresOnlyThumbStraight {
            guard
                GestureValidation.validateOnlyTargetFingersStraight(
                    gestureData,
                    targetFingers: [.thumb]
                )
            else { return false }
        }

        if requiresOnlyLittleFingerStraight {
            guard
                GestureValidation.validateOnlyTargetFingersStraight(
                    gestureData,
                    targetFingers: [.little]
                )
            else { return false }
        }

        if requiresAllFingersBent {
            guard GestureValidation.validateFistGesture(gestureData) else { return false }
        }

        // 2. Direction checks (moderate selectivity)
        for direction in GestureDetectionDirection.allCases {
            if requiresPalmFacing(direction) {
                guard gestureData.isPalmFacing(direction) else { return false }
            }
        }

        // 3. Individual finger direction checks (potentially expensive)
        for finger in FingerType.allCases {
            for direction in GestureDetectionDirection.allCases {
                if requiresFingerPointing(finger, direction: direction) {
                    guard gestureData.isFingerPointing(finger, direction: direction) else {
                        return false
                    }
                }
            }
        }

        // 4. Wrist and arm checks (least selective, checked last)
        if requiresWristStraight && !gestureData.isWristStraight { return false }
        if requiresWristBentInward && !gestureData.isWristBentInward { return false }
        if requiresWristBentOutward && !gestureData.isWristBentOutward { return false }
        if requiresArmExtended && !gestureData.armExtended { return false }

        return true
    }

    // MARK: - Gesture Confidence Scoring

    /// Calculates gesture matching confidence score (0.0-1.0)
    /// - Parameter gestureData: Gesture data to evaluate
    /// - Returns: Confidence score (1.0 is perfect match)
    public func confidenceScore(for gestureData: SingleHandGestureData) -> Double {
        var totalConditions = 0
        var matchedConditions = 0

        // Finger configuration checks
        if requiresOnlyIndexAndMiddleStraight {
            totalConditions += 1
            if GestureValidation.validateOnlyTargetFingersStraight(
                gestureData,
                targetFingers: [.index, .middle]
            ) {
                matchedConditions += 1
            }
        }

        if requiresOnlyIndexFingerStraight {
            totalConditions += 1
            if GestureValidation.validateOnlyTargetFingersStraight(
                gestureData,
                targetFingers: [.index]
            ) {
                matchedConditions += 1
            }
        }

        if requiresOnlyThumbStraight {
            totalConditions += 1
            if GestureValidation.validateOnlyTargetFingersStraight(
                gestureData,
                targetFingers: [.thumb]
            ) {
                matchedConditions += 1
            }
        }

        if requiresAllFingersBent {
            totalConditions += 1
            if GestureValidation.validateFistGesture(gestureData) {
                matchedConditions += 1
            }
        }

        // Palm direction checks
        for direction in GestureDetectionDirection.allCases {
            if requiresPalmFacing(direction) {
                totalConditions += 1
                if gestureData.isPalmFacing(direction) {
                    matchedConditions += 1
                }
            }
        }

        // Finger direction checks
        for finger in FingerType.allCases {
            for direction in GestureDetectionDirection.allCases {
                if requiresFingerPointing(finger, direction: direction) {
                    totalConditions += 1
                    if gestureData.isFingerPointing(finger, direction: direction) {
                        matchedConditions += 1
                    }
                }
            }
        }

        return totalConditions > 0 ? Double(matchedConditions) / Double(totalConditions) : 0.0
    }

    // MARK: - Debugging Support

    /// Gets detailed information about gesture conditions (for debugging)
    public var conditionsDescription: String {
        var conditions: [String] = []

        if requiresOnlyIndexAndMiddleStraight {
            conditions.append("Extend only index and middle fingers")
        }
        if requiresOnlyIndexFingerStraight {
            conditions.append("Extend only index finger")
        }
        if requiresOnlyThumbStraight {
            conditions.append("Extend only thumb")
        }
        if requiresAllFingersBent {
            conditions.append("Bend all fingers")
        }

        for direction in GestureDetectionDirection.allCases {
            if requiresPalmFacing(direction) {
                conditions.append("Face palm towards \(direction)")
            }
        }

        return conditions.isEmpty ? "No conditions" : conditions.joined(separator: ", ")
    }

    // MARK: - Gesture Comparison

    /// Calculates similarity with other gestures
    /// - Parameters:
    ///   - other: The gesture to compare with
    ///   - gestureData: Gesture data for testing
    /// - Returns: Similarity score (0.0-1.0)
    public func similarity(
        to other: SingleHandGestureProtocol, using gestureData: SingleHandGestureData
    ) -> Double {
        let thisScore = self.confidenceScore(for: gestureData)
        let otherScore = other.confidenceScore(for: gestureData)

        // Calculate similarity based on score difference
        let scoreDifference = abs(thisScore - otherScore)
        return 1.0 - scoreDifference
    }
}

// MARK: - Gesture Collection Extensions

extension Collection where Element == SingleHandGestureProtocol {

    /// Calculates confidence scores for all gestures against the specified gesture data
    /// - Parameter gestureData: Gesture data to evaluate
    /// - Returns: Array of tuples with gesture name and confidence score (sorted by confidence descending)
    public func confidenceScores(for gestureData: SingleHandGestureData) -> [(String, Double)] {
        return self.map { gesture in
            (gesture.gestureName, gesture.confidenceScore(for: gestureData))
        }.sorted { $0.1 > $1.1 }
    }

    /// Gets the gesture with the highest confidence
    /// - Parameter gestureData: Gesture data to evaluate
    /// - Returns: Gesture with highest confidence (nil if not found)
    public func mostConfidentGesture(for gestureData: SingleHandGestureData)
        -> SingleHandGestureProtocol?
    {
        return self.max { gesture1, gesture2 in
            gesture1.confidenceScore(for: gestureData) < gesture2.confidenceScore(for: gestureData)
        }
    }
}
