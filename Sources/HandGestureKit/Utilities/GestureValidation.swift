//
//  GestureValidation.swift
//  HandGesturePackage
//
//  Created by Claude Code on 2025/07/24.
//

import Foundation

/// Utility that provides common patterns frequently used in gesture detection
public enum GestureValidation {

    // MARK: - Finger Configuration Patterns

    /// Validate if the specified finger combination is in the correct state (straight/bent)
    /// - Parameters:
    ///   - gestureData: Hand gesture data
    ///   - straightFingers: Array of fingers that need to be straight
    ///   - bentFingers: Array of fingers that need to be bent
    /// - Returns: true if conditions are met
    public static func validateFingerConfiguration(
        _ gestureData: SingleHandGestureData,
        straight straightFingers: [FingerType],
        bent bentFingers: [FingerType]
    ) -> Bool {
        // Check straight fingers
        for finger in straightFingers {
            guard gestureData.isFingerStraight(finger) else { return false }
        }

        // Check bent fingers
        for finger in bentFingers {
            guard gestureData.isFingerBent(finger) else { return false }
        }

        return true
    }

    /// Validate that only the specified fingers are straight and other fingers are bent
    /// - Parameters:
    ///   - gestureData: Hand gesture data
    ///   - targetFingers: Array of fingers that need to be straight
    /// - Returns: true if conditions are met
    public static func validateOnlyTargetFingersStraight(
        _ gestureData: SingleHandGestureData,
        targetFingers: [FingerType]
    ) -> Bool {
        let allFingers = FingerType.allCases
        let targetSet = Set(targetFingers)
        let otherFingers = allFingers.filter { !targetSet.contains($0) }

        return validateFingerConfiguration(
            gestureData,
            straight: targetFingers,
            bent: otherFingers
        )
    }

    // MARK: - Direction Validation

    /// Validate that all specified fingers are pointing in the same direction
    /// - Parameters:
    ///   - gestureData: Hand gesture data
    ///   - fingers: Array of fingers to validate
    ///   - direction: Expected direction
    /// - Returns: true if all fingers are pointing in the specified direction
    public static func validateFingersPointingInDirection(
        _ gestureData: SingleHandGestureData,
        fingers: [FingerType],
        direction: GestureDetectionDirection
    ) -> Bool {
        return fingers.allSatisfy { finger in
            gestureData.isFingerPointing(finger, direction: direction)
        }
    }

    // MARK: - Complex Gesture Patterns

    /// Validate fist gesture state
    /// - Parameter gestureData: Hand gesture data
    /// - Returns: true if in fist state
    public static func validateFistGesture(_ gestureData: SingleHandGestureData) -> Bool {
        return FingerType.allCases.allSatisfy { finger in
            gestureData.isFingerBent(finger)
        }
    }

    /// Validate open hand (paper) gesture state
    /// - Parameter gestureData: Hand gesture data
    /// - Returns: true if in open hand state
    public static func validateOpenHandGesture(_ gestureData: SingleHandGestureData) -> Bool {
        return FingerType.allCases.allSatisfy { finger in
            gestureData.isFingerStraight(finger)
        }
    }

    /// Validate pointing gesture state (only index finger is straight)
    /// - Parameter gestureData: Hand gesture data
    /// - Returns: true if in pointing state
    public static func validatePointingGesture(_ gestureData: SingleHandGestureData) -> Bool {
        return validateOnlyTargetFingersStraight(
            gestureData,
            targetFingers: [.index]
        )
    }
}
