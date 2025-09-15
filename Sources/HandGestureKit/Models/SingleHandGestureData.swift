//
//  SingleHandGestureData.swift
//  HandGesturePackage
//
//  Created by Yugo Sugiyama on 2025/07/16.
//

import ARKit
import Foundation
import RealityKit

public enum GestureDetectionDirection: CaseIterable {
    case top
    case bottom
    case forward
    case backward
    case right
    case left
}

public enum HandKind {
    case right
    case left
}

public struct SingleHandGestureData {
    public let handTrackingComponent: HandTrackingComponent
    public let handKind: HandKind

    // Threshold settings - Parameters for adjusting gesture detection accuracy
    public let angleToleranceRadians: Float  // Angle tolerance for finger bend and arm extension detection
    public let distanceThreshold: Float  // Distance threshold for fingertip contact detection
    public let directionToleranceRadians: Float  // Direction tolerance angle for pointing and palm orientation

    // Pre-calculated values for performance optimization - Computed at initialization and reused
    private let palmNormal: SIMD3<Float>  // Palm normal vector
    private let forearmDirection: SIMD3<Float>  // Forearm direction vector
    private let wristPosition: SIMD3<Float>  // Wrist position
    private let isArmExtended: Bool  // Arm extension state (pre-determined)

    /// Initializer for SingleHandGestureData
    /// - Parameters:
    ///   - handTrackingComponent: Component containing hand tracking information
    ///   - handKind: Identifier indicating left or right hand
    ///   - angleToleranceRadians: Angle tolerance range (default 30 degrees) - Used for finger bend and arm extension detection
    ///   - distanceThreshold: Distance threshold (default 2cm) - Used for fingertip contact detection
    ///   - directionToleranceRadians: Direction tolerance angle (default 45 degrees) - Used for pointing and palm orientation detection
    public init(
        handTrackingComponent: HandTrackingComponent,
        handKind: HandKind,
        angleToleranceRadians: Float = .pi / 6,  // 30 degrees
        distanceThreshold: Float = 0.02,  // 2cm
        directionToleranceRadians: Float = .pi / 4  // 45 degrees
    ) {
        self.handTrackingComponent = handTrackingComponent
        self.handKind = handKind
        self.angleToleranceRadians = angleToleranceRadians
        self.distanceThreshold = distanceThreshold
        self.directionToleranceRadians = directionToleranceRadians

        // Pre-calculate values
        self.palmNormal = Self.calculatePalmNormal(from: handTrackingComponent)
        self.forearmDirection = Self.calculateForearmDirection(from: handTrackingComponent)
        self.wristPosition = Self.getWristPosition(from: handTrackingComponent)
        self.isArmExtended = Self.calculateArmExtension(
            from: handTrackingComponent, tolerance: angleToleranceRadians)
    }
}

// MARK: - 1. Public Getters and Functions Extension
extension SingleHandGestureData {

    // MARK: - Finger and palm direction detection

    /// Get the current direction the palm is facing
    /// Example: Returns .top when palm is facing upward
    public var palmDirection: GestureDetectionDirection {
        // Use the same logic as HandTrackingComponent's getPalmDirection()
        let palmDir = handTrackingComponent.getPalmDirection()

        // Convert from PalmDirection to GestureDetectionDirection
        switch palmDir {
        case .up: return .top
        case .down: return .bottom
        case .left: return .left
        case .right: return .right
        case .forward: return .forward
        case .backward: return .backward
        case .unknown: return .forward  // Default
        }
    }

    /// Determine if the palm is facing a specified direction
    /// Example: Check if palm is facing upward with isPalmFacing(.top)
    public func isPalmFacing(_ direction: GestureDetectionDirection) -> Bool {
        // Use the same logic as palmDirection property to maintain consistency
        return palmDirection == direction
    }

    /// Get the direction a specified finger is pointing
    /// Calculate finger direction vector from fingertip and intermediate joint positions
    public func fingerDirection(for finger: FingerType) -> GestureDetectionDirection {
        guard let tipJoint = getFingerTipJoint(for: finger),
            let intermediateJoint = getFingerIntermediateJoint(for: finger),
            let tipEntity = handTrackingComponent.fingers[tipJoint],
            let intermediateEntity = handTrackingComponent.fingers[intermediateJoint]
        else {
            return .forward  // Default value
        }

        let tipPos = tipEntity.position(relativeTo: nil)
        let intermediatePos = intermediateEntity.position(relativeTo: nil)
        let fingerVector = simd_normalize(tipPos - intermediatePos)

        return vectorToGestureDirection(fingerVector)
    }

    /// Determine if a specified finger is pointing in a specific direction
    /// Example: Check if index finger is pointing upward with isFingerPointing(.index, direction: .top)
    /// - Parameters:
    ///   - finger: The finger to check
    ///   - direction: The expected direction
    ///   - tolerance: Tolerance angle in radians. Uses directionToleranceRadians if nil
    public func isFingerPointing(
        _ finger: FingerType, direction: GestureDetectionDirection, tolerance: Float? = nil
    ) -> Bool {
        guard let tipJoint = getFingerTipJoint(for: finger),
            let intermediateJoint = getFingerIntermediateJoint(for: finger),
            let tipEntity = handTrackingComponent.fingers[tipJoint],
            let intermediateEntity = handTrackingComponent.fingers[intermediateJoint]
        else {
            return false
        }

        let tipPos = tipEntity.position(relativeTo: nil)
        let intermediatePos = intermediateEntity.position(relativeTo: nil)
        let fingerVector = simd_normalize(tipPos - intermediatePos)

        return isVectorFacing(fingerVector, direction: direction, tolerance: tolerance)
    }

    // MARK: - Finger bend detection

    /// Determine if a specified finger is bent (like in a closed fist)
    /// Returns true when joint angle exceeds the configured tolerance value
    public func isFingerBent(_ finger: FingerType) -> Bool {
        return handTrackingComponent.isFingerBent(finger, tolerance: angleToleranceRadians)
    }

    /// Determine if a specified finger is straight and extended
    /// Returns true when joint angle is within tolerance and close to straight
    public func isFingerStraight(_ finger: FingerType) -> Bool {
        // Call HandTrackingComponent extension's isFingerStraight method
        // Tolerance unified to 45 degrees (.pi/4)
        return handTrackingComponent.isFingerStraight(finger, tolerance: .pi / 4)
    }

    /// Determine finger bend level in stages
    public enum FingerBendLevel {
        case straight  // Fully extended (0-30 degrees)
        case slightlyBent  // Slightly bent (30-60 degrees)
        case moderatelyBent  // Moderately bent (60-90 degrees)
        case heavilyBent  // Heavily bent (90-120 degrees)
        case fullyBent  // Fully bent (120+ degrees)
    }

    /// Get the bend level of a specified finger
    public func getFingerBendLevel(_ finger: FingerType) -> FingerBendLevel {
        // Fully extended (within 30 degrees)
        if handTrackingComponent.isFingerStraight(finger, tolerance: .pi / 6) {
            return .straight
        }
        // Slightly bent (within 60 degrees)
        else if handTrackingComponent.isFingerStraight(finger, tolerance: .pi / 3) {
            return .slightlyBent
        }
        // Moderately bent (within 90 degrees)
        else if handTrackingComponent.isFingerStraight(finger, tolerance: .pi / 2) {
            return .moderatelyBent
        }
        // Heavily bent (within 120 degrees)
        else if handTrackingComponent.isFingerStraight(finger, tolerance: 2 * .pi / 3) {
            return .heavilyBent
        }
        // Fully bent (120+ degrees)
        else {
            return .fullyBent
        }
    }

    /// Determine if a specified finger is at a specific bend level
    public func isFingerAtBendLevel(_ finger: FingerType, level: FingerBendLevel) -> Bool {
        return getFingerBendLevel(finger) == level
    }

    /// Determine if a specified finger is bent at least to the minimum level
    public func isFingerBentAtLeast(_ finger: FingerType, minimumLevel: FingerBendLevel) -> Bool {
        let currentLevel = getFingerBendLevel(finger)
        switch minimumLevel {
        case .straight:
            return true  // Always true
        case .slightlyBent:
            return currentLevel != .straight
        case .moderatelyBent:
            return currentLevel == .moderatelyBent || currentLevel == .heavilyBent
                || currentLevel == .fullyBent
        case .heavilyBent:
            return currentLevel == .heavilyBent || currentLevel == .fullyBent
        case .fullyBent:
            return currentLevel == .fullyBent
        }
    }

    /// Determine if all fingers are bent (closed fist detection)
    /// Returns true when thumb, index, middle, ring, and little fingers are all bent
    public var isAllFingersBent: Bool {
        let fingers: [FingerType] = [.thumb, .index, .middle, .ring, .little]
        return fingers.allSatisfy { isFingerBent($0) }
    }

    /// Determine if all fingers except specified ones are bent
    /// Example: Used to detect pointing with index finger while other fingers are bent
    public func areAllFingersBentExcept(_ exceptFingers: [FingerType]) -> Bool {
        let allFingers: [FingerType] = [.thumb, .index, .middle, .ring, .little]
        let fingersToCheck = allFingers.filter { !exceptFingers.contains($0) }
        return fingersToCheck.allSatisfy { isFingerBent($0) }
    }

    // MARK: - Wrist bend detection

    /// Determine if wrist is bent outward (back of hand side)
    /// Detects when forearm and palm angle is greater than 90 degrees
    public var isWristBentOutward: Bool {
        guard let wrist = handTrackingComponent.fingers[.wrist],
            let middleMCP = handTrackingComponent.fingers[.middleFingerMetacarpal]
        else {
            return false
        }

        let wristPos = wrist.position(relativeTo: nil)
        let middlePos = middleMCP.position(relativeTo: nil)

        // Compare hand direction with forearm direction
        let handVector = simd_normalize(middlePos - wristPos)
        let angle = acos(max(-1.0, min(1.0, simd_dot(handVector, forearmDirection))))

        // Consider angles greater than 90 degrees as outward bending
        return angle > (.pi / 2 + angleToleranceRadians)
    }

    /// Determine if wrist is bent inward (palm side)
    /// Detects when forearm and palm angle is less than 90 degrees
    public var isWristBentInward: Bool {
        guard let wrist = handTrackingComponent.fingers[.wrist],
            let middleMCP = handTrackingComponent.fingers[.middleFingerMetacarpal]
        else {
            return false
        }

        let wristPos = wrist.position(relativeTo: nil)
        let middlePos = middleMCP.position(relativeTo: nil)

        // Compare hand direction with forearm direction
        let handVector = simd_normalize(middlePos - wristPos)
        let angle = acos(max(-1.0, min(1.0, simd_dot(handVector, forearmDirection))))

        // Consider angles less than 90 degrees as inward bending
        return angle < (.pi / 2 - angleToleranceRadians)
    }

    /// Determine if wrist is straight (natural position)
    /// Detects neutral state where wrist is not bent inward or outward
    public var isWristStraight: Bool {
        return !isWristBentInward && !isWristBentOutward
    }

    // MARK: - Arm extension state

    /// Determine if arm is extended (pre-calculated)
    /// Returns true when forearm-wrist-palm are in a near-straight line (close to 180 degrees)
    public var armExtended: Bool {
        return isArmExtended
    }

    // MARK: - Arm extension direction

    /// Get the direction the arm is extended
    /// Determine and return the strongest directional component from forearm direction vector
    public var armDirection: GestureDetectionDirection {
        return vectorToGestureDirection(forearmDirection)
    }

    /// Determine if arm is extended in a specific direction
    /// Returns true when arm is in extended state and facing specified direction
    /// Example: Check if arm is raised upward with isArmExtendedInDirection(.top)
    public func isArmExtendedInDirection(_ direction: GestureDetectionDirection) -> Bool {
        return armExtended && isVectorFacing(forearmDirection, direction: direction)
    }
}

// MARK: - 2. Static Helper Methods Extension (Private)
extension SingleHandGestureData {

    // MARK: - Private Static Helper Methods for Pre-computation

    /// Calculate palm normal vector (executed at initialization)
    /// Determine palm plane normal from three points: wrist, index finger base, little finger base
    fileprivate static func calculatePalmNormal(from component: HandTrackingComponent) -> SIMD3<
        Float
    > {
        guard let wrist = component.fingers[.wrist],
            let indexMCP = component.fingers[.indexFingerMetacarpal],
            let littleMCP = component.fingers[.littleFingerMetacarpal]
        else {
            return SIMD3<Float>(0, 0, 1)  // Default value
        }

        let wristPos = wrist.position(relativeTo: nil)
        let indexPos = indexMCP.position(relativeTo: nil)
        let littlePos = littleMCP.position(relativeTo: nil)

        let v1 = indexPos - wristPos
        let v2 = littlePos - wristPos
        let normal = simd_cross(v1, v2)

        return simd_normalize(normal)
    }

    /// Calculate forearm direction vector (executed at initialization)
    /// Determine direction from forearm joint to wrist, used as arm orientation
    fileprivate static func calculateForearmDirection(from component: HandTrackingComponent)
        -> SIMD3<Float>
    {
        guard let wrist = component.fingers[.wrist],
            let forearm = component.fingers[.forearmArm]
        else {
            return SIMD3<Float>(0, 1, 0)  // Default value (upward)
        }

        let wristPos = wrist.position(relativeTo: nil)
        let forearmPos = forearm.position(relativeTo: nil)

        return simd_normalize(wristPos - forearmPos)
    }

    /// Get wrist position (executed at initialization)
    /// Used as reference point for various calculations
    fileprivate static func getWristPosition(from component: HandTrackingComponent) -> SIMD3<Float>
    {
        return component.fingers[.wrist]?.position(relativeTo: nil) ?? SIMD3<Float>.zero
    }

    /// Calculate arm extension state (executed at initialization)
    /// Determine if three points (forearm-wrist-palm) are close to a straight line using angle
    fileprivate static func calculateArmExtension(
        from component: HandTrackingComponent, tolerance: Float
    ) -> Bool {
        guard let wrist = component.fingers[.wrist],
            let forearm = component.fingers[.forearmArm],
            let middleMCP = component.fingers[.middleFingerMetacarpal]
        else {
            return false
        }

        let wristPos = wrist.position(relativeTo: nil)
        let forearmPos = forearm.position(relativeTo: nil)
        let middlePos = middleMCP.position(relativeTo: nil)

        // Calculate angle between forearm-wrist-palm
        let v1 = simd_normalize(forearmPos - wristPos)
        let v2 = simd_normalize(middlePos - wristPos)

        let angle = acos(max(-1.0, min(1.0, simd_dot(v1, v2))))

        // Consider near-straight line (close to 180 degrees) as extended
        return abs(angle - .pi) <= tolerance
    }

    /// Check if all fingers are extended
    /// - Returns: true if all fingers are extended
    public func areAllFingersExtended() -> Bool {
        let fingers: [FingerType] = [.thumb, .index, .middle, .ring, .little]
        return fingers.allSatisfy { isFingerStraight($0) }
    }

    /// Get general direction of fingertips (average of multiple fingers)
    /// - Returns: Average direction of fingertips
    public func fingerTipsGeneralDirection() -> GestureDetectionDirection {
        let fingers: [FingerType] = [.index, .middle, .ring, .little]  // Excluding thumb
        let directions = fingers.map { fingerDirection(for: $0) }

        // Return the most frequent direction
        let directionCounts = directions.reduce(into: [:]) { counts, direction in
            counts[direction, default: 0] += 1
        }

        return directionCounts.max(by: { $0.value < $1.value })?.key ?? .forward
    }
}

// MARK: - 3. Private Instance Helper Methods Extension
extension SingleHandGestureData {

    // MARK: - Direction conversion helpers

    /// Determine strongest directional component from 3D vector and convert to GestureDetectionDirection
    /// Example: Returns .top for upward vector (0, 1, 0)
    fileprivate func vectorToGestureDirection(_ vector: SIMD3<Float>) -> GestureDetectionDirection {
        let absX = abs(vector.x)
        let absY = abs(vector.y)
        let absZ = abs(vector.z)

        // Determine direction by largest component
        if absY > absX && absY > absZ {
            return vector.y > 0 ? .top : .bottom
        } else if absZ > absX && absZ > absY {
            return vector.z > 0 ? .backward : .forward
        } else {
            return vector.x > 0 ? .right : .left
        }
    }

    /// Determine if specified vector is facing a specific direction using angle
    /// Consider as match if within configured tolerance angle (directionToleranceRadians)
    fileprivate func isVectorFacing(
        _ vector: SIMD3<Float>, direction: GestureDetectionDirection, tolerance: Float? = nil
    ) -> Bool {
        let targetVector: SIMD3<Float>
        switch direction {
        case .top: targetVector = SIMD3<Float>(0, 1, 0)  // Upward direction
        case .bottom: targetVector = SIMD3<Float>(0, -1, 0)  // Downward direction
        case .forward: targetVector = SIMD3<Float>(0, 0, -1)  // Forward direction
        case .backward: targetVector = SIMD3<Float>(0, 0, 1)  // Backward direction
        case .right: targetVector = SIMD3<Float>(1, 0, 0)  // Right direction
        case .left: targetVector = SIMD3<Float>(-1, 0, 0)  // Left direction
        }

        let normalizedVector = simd_normalize(vector)
        let dotProduct = simd_dot(normalizedVector, targetVector)
        let angle = acos(max(-1.0, min(1.0, dotProduct)))

        let effectiveTolerance = tolerance ?? directionToleranceRadians
        return angle <= effectiveTolerance
    }

    // MARK: - Helper Methods (Internal auxiliary methods)

    /// Helper method to get the fingertip joint name for a specified finger
    /// Used when calculating finger direction
    fileprivate func getFingerTipJoint(for finger: FingerType) -> HandSkeleton.JointName? {
        switch finger {
        case .thumb: return .thumbTip
        case .index: return .indexFingerTip
        case .middle: return .middleFingerTip
        case .ring: return .ringFingerTip
        case .little: return .littleFingerTip
        }
    }

    /// Helper method to get the intermediate joint name for a specified finger
    /// Used in pair with fingertip joint when calculating finger direction vector
    fileprivate func getFingerIntermediateJoint(for finger: FingerType) -> HandSkeleton.JointName? {
        switch finger {
        case .thumb: return .thumbIntermediateTip
        case .index: return .indexFingerIntermediateTip
        case .middle: return .middleFingerIntermediateTip
        case .ring: return .ringFingerIntermediateTip
        case .little: return .littleFingerIntermediateTip
        }
    }
}
