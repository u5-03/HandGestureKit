//
//  HandsGestureData.swift
//  HandGesturePackage
//
//  Created by Claude on 2025/07/26.
//

import ARKit
import Foundation
import RealityKit
import simd

/// Structure that holds gesture data for both hands
public struct HandsGestureData {
    /// Gesture data for the left hand
    public let leftHand: SingleHandGestureData

    /// Gesture data for the right hand
    public let rightHand: SingleHandGestureData

    /// Initialization method
    public init(leftHand: SingleHandGestureData, rightHand: SingleHandGestureData) {
        self.leftHand = leftHand
        self.rightHand = rightHand
    }
}

// MARK: - Methods for calculating relationships between both hands
extension HandsGestureData {

    /// Get the distance between both palms
    public var palmDistance: Float {
        let leftPalmPos =
            leftHand.handTrackingComponent.fingers[.wrist]?.position(relativeTo: nil) ?? .zero
        let rightPalmPos =
            rightHand.handTrackingComponent.fingers[.wrist]?.position(relativeTo: nil) ?? .zero
        return simd_distance(leftPalmPos, rightPalmPos)
    }

    /// Get the 3D position of a specific joint
    public func getJointPosition(hand: HandKind, joint: HandSkeleton.JointName) -> SIMD3<Float>? {
        let component =
            hand == .left ? leftHand.handTrackingComponent : rightHand.handTrackingComponent
        return component.fingers[joint]?.position(relativeTo: nil)
    }

    /// Get the distance between the same joints on both hands
    public func jointDistance(joint: HandSkeleton.JointName) -> Float {
        guard let leftPos = getJointPosition(hand: .left, joint: joint),
            let rightPos = getJointPosition(hand: .right, joint: joint)
        else {
            return Float.infinity
        }
        return simd_distance(leftPos, rightPos)
    }

    /// Get the distance between corresponding finger joints on both hands
    public func correspondingFingerJointDistance(
        leftJoint: HandSkeleton.JointName, rightJoint: HandSkeleton.JointName
    ) -> Float {
        guard let leftPos = getJointPosition(hand: .left, joint: leftJoint),
            let rightPos = getJointPosition(hand: .right, joint: rightJoint)
        else {
            return Float.infinity
        }
        return simd_distance(leftPos, rightPos)
    }

    /// Get the distance between the center positions of both palms (more accurate palm distance)
    public var palmCenterDistance: Float {
        // Calculate the palm center as the average position of finger bases
        // Note: knuckle refers to the first joint of fingers (MCP joint)
        guard let leftThumbKnuckle = getJointPosition(hand: .left, joint: .thumbKnuckle),
            let leftIndexKnuckle = getJointPosition(hand: .left, joint: .indexFingerKnuckle),
            let leftMiddleKnuckle = getJointPosition(hand: .left, joint: .middleFingerKnuckle),
            let leftRingKnuckle = getJointPosition(hand: .left, joint: .ringFingerKnuckle),
            let leftLittleKnuckle = getJointPosition(hand: .left, joint: .littleFingerKnuckle),
            let rightThumbKnuckle = getJointPosition(hand: .right, joint: .thumbKnuckle),
            let rightIndexKnuckle = getJointPosition(hand: .right, joint: .indexFingerKnuckle),
            let rightMiddleKnuckle = getJointPosition(hand: .right, joint: .middleFingerKnuckle),
            let rightRingKnuckle = getJointPosition(hand: .right, joint: .ringFingerKnuckle),
            let rightLittleKnuckle = getJointPosition(hand: .right, joint: .littleFingerKnuckle)
        else {
            return Float.infinity
        }

        // Left palm center (average of 5 finger bases)
        let leftPalmCenter =
            (leftThumbKnuckle + leftIndexKnuckle + leftMiddleKnuckle + leftRingKnuckle
                + leftLittleKnuckle) / 5

        // Right palm center (average of 5 finger bases)
        let rightPalmCenter =
            (rightThumbKnuckle + rightIndexKnuckle + rightMiddleKnuckle + rightRingKnuckle
                + rightLittleKnuckle) / 5

        return simd_distance(leftPalmCenter, rightPalmCenter)
    }

    /// Distance between both middle finger bases (simple palm distance)
    public var middleKnuckleDistance: Float {
        return jointDistance(joint: .middleFingerKnuckle)
    }

    /// Get the vertical offset between both hands (Y-axis difference)
    public var verticalOffset: Float {
        guard let leftWrist = getJointPosition(hand: .left, joint: .wrist),
            let rightWrist = getJointPosition(hand: .right, joint: .wrist)
        else {
            return Float.infinity
        }
        return abs(leftWrist.y - rightWrist.y)
    }

    /// Get the distance between specific fingertips on both hands
    public func fingerTipDistance(leftFinger: FingerType, rightFinger: FingerType) -> Float {
        guard let leftJoint = getFingerTipJoint(for: leftFinger),
            let rightJoint = getFingerTipJoint(for: rightFinger),
            let leftEntity = leftHand.handTrackingComponent.fingers[leftJoint],
            let rightEntity = rightHand.handTrackingComponent.fingers[rightJoint]
        else {
            return Float.infinity
        }

        let leftPos = leftEntity.position(relativeTo: nil)
        let rightPos = rightEntity.position(relativeTo: nil)
        return simd_distance(leftPos, rightPos)
    }

    /// Determine if both palms are facing each other
    public var arePalmsFacingEachOther: Bool {
        // When the dot product of left and right palm normals is negative, they are facing each other
        let leftNormal = getNormalizedPalmNormal(for: leftHand)
        let rightNormal = getNormalizedPalmNormal(for: rightHand)
        let dotProduct = simd_dot(leftNormal, rightNormal)

        // -0.7 or less means facing each other at approximately 135 degrees or more
        return dotProduct < -0.7
    }

    /// Determine if both hands are parallel
    public var areHandsParallel: Bool {
        let leftNormal = getNormalizedPalmNormal(for: leftHand)
        let rightNormal = getNormalizedPalmNormal(for: rightHand)
        let dotProduct = abs(simd_dot(leftNormal, rightNormal))

        // 0.9 or more means parallel within approximately 25 degrees
        return dotProduct > 0.9
    }

    /// Get the center position between both hands
    public var centerPosition: SIMD3<Float> {
        let leftPos =
            leftHand.handTrackingComponent.fingers[.wrist]?.position(relativeTo: nil) ?? .zero
        let rightPos =
            rightHand.handTrackingComponent.fingers[.wrist]?.position(relativeTo: nil) ?? .zero
        return (leftPos + rightPos) / 2
    }

    // MARK: - Helper Methods

    private func getFingerTipJoint(for finger: FingerType) -> HandSkeleton.JointName? {
        switch finger {
        case .thumb: return .thumbTip
        case .index: return .indexFingerTip
        case .middle: return .middleFingerTip
        case .ring: return .ringFingerTip
        case .little: return .littleFingerTip
        }
    }

    private func getNormalizedPalmNormal(for hand: SingleHandGestureData) -> SIMD3<Float> {
        guard let wrist = hand.handTrackingComponent.fingers[.wrist],
            let indexKnuckle = hand.handTrackingComponent.fingers[.indexFingerKnuckle],
            let littleKnuckle = hand.handTrackingComponent.fingers[.littleFingerKnuckle]
        else {
            return SIMD3<Float>(0, 0, 1)
        }

        let wristPos = wrist.position(relativeTo: nil)
        let indexPos = indexKnuckle.position(relativeTo: nil)
        let littlePos = littleKnuckle.position(relativeTo: nil)

        let v1 = indexPos - wristPos
        let v2 = littlePos - wristPos
        let normal = simd_cross(v1, v2)

        // Adjust normal direction for left and right hands
        let normalizedNormal = simd_normalize(normal)

        // For right hand, invert the normal (so palm faces inward)
        if hand.handKind == .right {
            return -normalizedNormal
        }

        return normalizedNormal
    }

    // MARK: - Position validation helper methods

    /// Check if a hand is at a specified distance from eye level
    /// - Parameters:
    ///   - hand: Target hand (left or right)
    ///   - fromEyeLevel: Distance from eye level (meters)
    ///   - tolerance: Tolerance error (meters)
    /// - Returns: true if within the specified range
    public func isHandAtRelativeHeight(hand: HandKind, fromEyeLevel: Float, tolerance: Float = 0.05)
        -> Bool
    {
        // Note: Since actual eye level height cannot be obtained, use relative position
        // Use height from device reference point (usually initial position)
        guard let wristPos = getJointPosition(hand: hand, joint: .wrist) else {
            return false
        }

        // Reference height (assume 1.5m as eye level height)
        let eyeLevel: Float = 1.5
        let targetHeight = eyeLevel - fromEyeLevel

        // Judge by Y coordinate
        let difference = abs(wristPos.y - targetHeight)
        return difference <= tolerance
    }

    /// Get the vertical distance between both hands
    /// - Returns: Vertical distance (meters). Positive value when right hand is above
    public func handVerticalSeparation() -> Float {
        guard let leftWrist = getJointPosition(hand: .left, joint: .wrist),
            let rightWrist = getJointPosition(hand: .right, joint: .wrist)
        else {
            return 0
        }
        return rightWrist.y - leftWrist.y
    }

    /// Check if a specified joint is near another joint
    /// - Parameters:
    ///   - joint1: First joint
    ///   - hand1: First hand
    ///   - joint2: Second joint
    ///   - hand2: Second hand
    ///   - maxDistance: Maximum distance (meters)
    /// - Returns: true if within the specified distance
    public func areJointsClose(
        joint1: HandSkeleton.JointName,
        hand1: HandKind,
        joint2: HandSkeleton.JointName,
        hand2: HandKind,
        maxDistance: Float
    ) -> Bool {
        guard let pos1 = getJointPosition(hand: hand1, joint: joint1),
            let pos2 = getJointPosition(hand: hand2, joint: joint2)
        else {
            return false
        }
        return simd_distance(pos1, pos2) <= maxDistance
    }

    /// Get the distance between specific joints on different hands
    /// - Parameters:
    ///   - joint1: First joint
    ///   - hand1: First hand
    ///   - joint2: Second joint
    ///   - hand2: Second hand
    /// - Returns: Distance between joints (meters). Float.infinity if joints are not found
    public func jointToJointDistance(
        joint1: HandSkeleton.JointName,
        hand1: HandKind,
        joint2: HandSkeleton.JointName,
        hand2: HandKind
    ) -> Float {
        guard let pos1 = getJointPosition(hand: hand1, joint: joint1),
            let pos2 = getJointPosition(hand: hand2, joint: joint2)
        else {
            return Float.infinity
        }
        return simd_distance(pos1, pos2)
    }
}
