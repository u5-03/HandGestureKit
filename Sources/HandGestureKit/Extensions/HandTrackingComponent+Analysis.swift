import ARKit
import RealityKit
import simd

// Vector normalization function
func normalize(_ vector: SIMD3<Float>) -> SIMD3<Float> {
    let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    if length > 0 {
        return vector / length
    }
    return vector
}

// MARK: - HandTrackingComponent Extension
extension HandTrackingComponent {

    // MARK: - 1. Determining if fingers are bent

    /// Determine if a finger is straight
    /// - Parameters:
    ///   - finger: Type of finger to check
    ///   - tolerance: Tolerance angle (radians). Default is 45 degrees
    /// - Returns: true if finger is straight, false if bent
    public func isFingerStraight(_ finger: FingerType, tolerance: Float = .pi / 4) -> Bool {
        let joints = getFingerJoints(finger)
        guard joints.count >= 3 else {
            if finger == .index {
                HandGestureLogger.logDebug(
                    "⚠️ \(finger.description) finger: Insufficient joint count (\(joints.count))")
            }
            return false
        }

        // Don't output detailed logs for fingers other than index finger
        // Suppress index finger logs in sign language mode too
        let shouldLogDetails = false  // finger == .index

        // Get joints sequentially from finger base to tip
        var positions: [SIMD3<Float>] = []

        if shouldLogDetails {
            HandGestureLogger.logDebug("🔍 \(finger.description) finger joint coordinates:")
        }

        for (i, joint) in joints.enumerated() {
            guard let entity = fingers[joint] else {
                if shouldLogDetails {
                    HandGestureLogger.logDebug("⚠️ \(finger.description) finger: Joint \(joint) not found")
                }
                return false
            }
            let position = entity.position(relativeTo: nil)
            positions.append(position)

            if shouldLogDetails {
                HandGestureLogger.logDebug(
                    "  \(i): \(joint) = (\(String(format: "%.3f", position.x)), \(String(format: "%.3f", position.y)), \(String(format: "%.3f", position.z)))"
                )
            }
        }

        // Check angles of three consecutive joints
        var allAngles: [Float] = []
        var deviationCount = 0  // Number of angles exceeding tolerance

        for i in 0..<(positions.count - 2) {
            let angle = calculateAngleBetweenPoints(
                p1: positions[i],
                p2: positions[i + 1],
                p3: positions[i + 2]
            )
            allAngles.append(angle)

            if shouldLogDetails {
                let angleDegrees = angle * 180 / .pi
                // Calculate difference from 180 degrees
                let straightAngle: Float = .pi
                let deviation = abs(angle - straightAngle)
                let deviationDegrees = deviation * 180 / .pi

                HandGestureLogger.logDebug(
                    "  Angle \(i)-\(i+1)-\(i+2): \(String(format: "%.1f", angleDegrees))° (Diff from 180°: \(String(format: "%.1f", deviationDegrees))°, Tolerance: \(String(format: "%.1f", tolerance * 180 / .pi))°)"
                )
            }

            // Count angles exceeding tolerance
            let straightAngle: Float = .pi
            let deviation = abs(angle - straightAngle)
            if deviation > tolerance {
                deviationCount += 1
                if shouldLogDetails {
                    HandGestureLogger.logDebug("  ⚠️ Joint \(i)-\(i+1)-\(i+2) angle exceeds tolerance")
                }
            }
        }

        // For multiple joints, consider straight even if only one exceeds tolerance
        // (Finger base parts are often bent)
        let isStraight = allAngles.count > 2 ? deviationCount <= 1 : deviationCount == 0

        if shouldLogDetails {
            let averageAngle = allAngles.reduce(0, +) / Float(allAngles.count)
            let averageAngleDegrees = averageAngle * 180 / .pi

            if isStraight {
                HandGestureLogger.logDebug(
                    "📏 \(finger.description) finger: Straight (Average angle: \(String(format: "%.1f", averageAngleDegrees))°)"
                )
            } else {
                HandGestureLogger.logDebug(
                    "📏 \(finger.description) finger: Bent (Average angle: \(String(format: "%.1f", averageAngleDegrees))°, Joints exceeding tolerance: \(deviationCount))"
                )
            }
        }

        return isStraight
    }

    /// Determine if a finger is bent (opposite of isFingerStraight)
    public func isFingerBent(_ finger: FingerType, tolerance: Float = .pi / 4) -> Bool {
        return !isFingerStraight(finger, tolerance: tolerance)
    }

    // MARK: - 2. Palm orientation determination

    /// Common logic to determine direction from normal vector
    private func getDirectionFromNormal(_ normal: SIMD3<Float>) -> PalmDirection {
        // Perform different judgments for left and right hands
        let isLeftHand = chirality == .left

        // Calculate angles with each direction and select the closest
        var closestDirection = PalmDirection.backward
        var smallestAngle: Float = .pi

        // Boundary value adjustment (changed from 45 to 30 degrees)

        for direction in PalmDirection.allCases {
            var targetVector = direction.vector

            // For left hand, adjust direction vector
            if isLeftHand {
                if direction == .forward || direction == .backward {
                    // For left hand, invert forward/backward direction
                    targetVector = -targetVector
                } else if direction == .up || direction == .down {
                    // For left hand, invert up/down direction
                    targetVector = -targetVector
                } else if direction == .left || direction == .right {
                    // For left hand, invert left/right direction
                    targetVector = -targetVector
                }
            }

            // Calculate dot product between normalized vectors (cosine similarity)
            let dotProduct = simd_dot(normalize(normal), normalize(targetVector))
            // Calculate radian angle from dot product
            let angle = acos(max(-1.0, min(1.0, dotProduct)))

            // Update minimum angle
            if angle < smallestAngle {
                smallestAngle = angle
                closestDirection = direction
            }
        }

        return closestDirection
    }

    /// Determine if palm is facing a specific direction using angle (more flexible)
    /// - Parameters:
    ///   - direction: Direction to check
    ///   - tolerance: Tolerance angle (radians). Default is 30 degrees
    /// - Returns: true if facing the specified direction
    public func isPalmFacingDirection(_ direction: PalmDirection, tolerance: Float = .pi / 6)
        -> Bool
    {
        guard fingers[.wrist] != nil else { return false }

        // Perform different judgments for left and right hands
        let isLeftHand = chirality == .left

        // Get palm normal vector
        let palmNormalToUse = calculatePalmNormal()

        // Vector for specified direction
        var targetVector = direction.vector

        // For left hand, adjust direction vector
        if isLeftHand {
            if direction == .forward || direction == .backward {
                // For left hand, invert forward/backward direction
                targetVector = -targetVector
            } else if direction == .up || direction == .down {
                // For left hand, invert up/down direction
                targetVector = -targetVector
            } else if direction == .left || direction == .right {
                // For left hand, invert left/right direction
                targetVector = -targetVector
            }
        }

        // Calculate angle between vectors
        let dotProduct = simd_dot(normalize(palmNormalToUse), normalize(targetVector))
        let angle = acos(max(-1.0, min(1.0, dotProduct)))

        // Determine if within tolerance angle
        return angle <= tolerance
    }

    /// Calculate the palm normal vector (try multiple methods and return the most reliable result)
    private func calculatePalmNormal() -> SIMD3<Float> {
        guard let wrist = fingers[.wrist] else { return SIMD3<Float>(0, 0, 1) }

        // Method 1: Get orientation from wrist AnchorEntity
        let wristTransform = wrist.transform
        let palmNormal1 = wristTransform.rotation.act(SIMD3<Float>(0, 0, 1))

        // Method 2: Calculate using hand joints (more accurate)
        var palmNormal2: SIMD3<Float>? = nil

        // Method 2a: Get 3 points that define the palm plane (metacarpal joints)
        if let wristPos = fingers[.wrist]?.position(relativeTo: nil),
            let indexMCP = fingers[.indexFingerMetacarpal]?.position(relativeTo: nil),
            let littleMCP = fingers[.littleFingerMetacarpal]?.position(relativeTo: nil)
        {

            // Two vectors defining the palm plane
            let v1 = indexMCP - wristPos
            let v2 = littleMCP - wristPos

            // Calculate normal vector using cross product
            let crossProduct = simd_cross(v1, v2)
            palmNormal2 = normalize(crossProduct)
        }
        // Method 2b: Use knuckles (finger bases)
        else if let wristPos = fingers[.wrist]?.position(relativeTo: nil),
            let indexKnuckle = fingers[.indexFingerKnuckle]?.position(relativeTo: nil),
            let littleKnuckle = fingers[.littleFingerKnuckle]?.position(relativeTo: nil)
        {

            // Two vectors defining the palm plane
            let v1 = indexKnuckle - wristPos
            let v2 = littleKnuckle - wristPos

            // Calculate normal vector using cross product
            let crossProduct = simd_cross(v1, v2)
            palmNormal2 = normalize(crossProduct)
        }
        // Method 2c: Use middle finger and thumb knuckles
        else if let wristPos = fingers[.wrist]?.position(relativeTo: nil),
            let middleKnuckle = fingers[.middleFingerKnuckle]?.position(relativeTo: nil),
            let thumbKnuckle = fingers[.thumbKnuckle]?.position(relativeTo: nil)
        {

            // Two vectors defining the palm plane
            let v1 = middleKnuckle - wristPos
            let v2 = thumbKnuckle - wristPos

            // Calculate normal vector using cross product
            let crossProduct = simd_cross(v1, v2)
            palmNormal2 = normalize(crossProduct)
        }

        // Determine which normal vector to use
        let palmNormalToUse: SIMD3<Float>

        if palmNormal1.x == 0 && palmNormal1.y == 0 && palmNormal1.z == 1,
            let normal2 = palmNormal2
        {
            // If method 1 result is a fixed value, use method 2
            palmNormalToUse = normal2
        } else if let normal2 = palmNormal2 {
            // If both methods are available, prioritize method 2 (more accurate)
            palmNormalToUse = normal2
        } else {
            // If method 2 is not available, use method 1
            palmNormalToUse = palmNormal1
        }

        return palmNormalToUse
    }

    /// Determine the direction the palm is facing
    /// - Returns: Palm direction
    public func getPalmDirection() -> PalmDirection {
        // Calculate palm normal vector
        let palmNormal = calculatePalmNormal()

        // Determine direction from normal vector
        return getDirectionFromNormal(palmNormal)
    }

    /// Determine if the palm is facing a specific direction
    public func isPalmFacing(_ direction: PalmDirection) -> Bool {
        return getPalmDirection() == direction
    }

    /// Determine if the palm is facing backward based on angle (more flexible)
    /// - Parameter tolerance: Tolerance angle (radians). Default is 45 degrees
    /// - Returns: true if facing backward
    public func isPalmFacingBackward(tolerance: Float = .pi / 4) -> Bool {
        return isPalmFacingDirection(.backward, tolerance: tolerance)
    }

    /// Determine if palm is facing forward using angle (more flexible)
    public func isPalmFacingForward(tolerance: Float = .pi / 6) -> Bool {
        return isPalmFacingDirection(.forward, tolerance: tolerance)
    }

    /// Determine if palm is facing up using angle (more flexible)
    public func isPalmFacingUp(tolerance: Float = .pi / 6) -> Bool {
        return isPalmFacingDirection(.up, tolerance: tolerance)
    }

    /// Determine if palm is facing down using angle (more flexible)
    public func isPalmFacingDown(tolerance: Float = .pi / 6) -> Bool {
        return isPalmFacingDirection(.down, tolerance: tolerance)
    }

    // MARK: - 3. Fingertip contact detection

    /// Determine if two fingertips are touching
    /// - Parameters:
    ///   - finger1: First finger
    ///   - finger2: Second finger
    ///   - threshold: Distance threshold for contact detection (meters). Default is 2cm
    /// - Returns: true if touching
    public func areFingerTipsTouching(
        _ finger1: FingerType, _ finger2: FingerType, threshold: Float = 0.02
    ) -> Bool {
        let tip1Joint = getFingerTipJoint(finger1)
        let tip2Joint = getFingerTipJoint(finger2)

        guard let tip1Entity = fingers[tip1Joint],
            let tip2Entity = fingers[tip2Joint]
        else {
            return false
        }

        let tip1Pos = tip1Entity.position(relativeTo: nil)
        let tip2Pos = tip2Entity.position(relativeTo: nil)

        let distance = simd_distance(tip1Pos, tip2Pos)
        return distance <= threshold
    }

    /// Determine if thumb is touching another finger (used for OK sign, etc.)
    public func isThumbTouchingFinger(_ finger: FingerType, threshold: Float = 0.02) -> Bool {
        return areFingerTipsTouching(.thumb, finger, threshold: threshold)
    }

    // MARK: - 4. Finger direction detection

    /// Determine the direction a finger is pointing
    /// - Parameter finger: Finger to check
    /// - Returns: Finger direction
    public func getFingerDirection(_ finger: FingerType) -> PalmDirection {
        let tipJoint = getFingerTipJoint(finger)
        guard let tipEntity = fingers[tipJoint] else { return .backward }

        // Get the orientation of the fingertip AnchorEntity
        let tipTransform = tipEntity.transform

        // Calculate finger direction vector (negative Z-axis from fingertip is the finger direction)
        let fingerDirection = tipTransform.rotation.act(SIMD3<Float>(0, 0, -1))

        // Show debug information only for index finger
        if finger == .index {
            // Display normal vector values for debugging
            HandGestureLogger.logDebug(
                "👆 \(finger) direction vector: (\(String(format: "%.3f", fingerDirection.x)), \(String(format: "%.3f", fingerDirection.y)), \(String(format: "%.3f", fingerDirection.z)))"
            )

            // Get absolute values of each axis component
            let absX = abs(fingerDirection.x)
            let absY = abs(fingerDirection.y)
            let absZ = abs(fingerDirection.z)

            // Display absolute values for debugging
            HandGestureLogger.logDebug(
                "👆 \(finger) absolute values: X=\(String(format: "%.3f", absX)), Y=\(String(format: "%.3f", absY)), Z=\(String(format: "%.3f", absZ))"
            )
        }

        // Get absolute values of each axis component
        let absX = abs(fingerDirection.x)
        let absY = abs(fingerDirection.y)
        let absZ = abs(fingerDirection.z)

        // Determine direction based on the largest component
        let direction: PalmDirection
        if absY > absX && absY > absZ {
            direction = fingerDirection.y > 0 ? .up : .down
        } else if absZ > absX && absZ > absY {
            direction = fingerDirection.z > 0 ? .backward : .forward
        } else {
            direction = fingerDirection.x > 0 ? .right : .left
        }

        // Display direction determination result only for index finger
        if finger == .index {
            HandGestureLogger.logDebug("👆 \(finger) direction determination result: \(direction)")
        }

        return direction
    }

    /// Determine if finger is pointing in a specific direction
    /// - Parameters:
    ///   - finger: Finger to evaluate
    ///   - direction: Expected direction
    /// - Returns: true if pointing in the specified direction
    public func isFingerPointing(_ finger: FingerType, direction: PalmDirection) -> Bool {
        return getFingerDirection(finger) == direction
    }

    /// Determine if finger is pointing upward
    /// - Parameter finger: Finger to evaluate
    /// - Returns: true if pointing upward
    public func isFingerPointingUp(_ finger: FingerType) -> Bool {
        return isFingerPointing(finger, direction: .up)
    }

    /// Determine if finger is pointing downward
    /// - Parameter finger: Finger to evaluate
    /// - Returns: true if pointing downward
    public func isFingerPointingDown(_ finger: FingerType) -> Bool {
        return isFingerPointing(finger, direction: .down)
    }

    /// Determine if finger is pointing forward
    /// - Parameter finger: Finger to evaluate
    /// - Returns: true if pointing forward
    public func isFingerPointingForward(_ finger: FingerType) -> Bool {
        return isFingerPointing(finger, direction: .forward)
    }

    /// Determine if finger is pointing backward
    /// - Parameter finger: Finger to evaluate
    /// - Returns: true if pointing backward
    public func isFingerPointingBackward(_ finger: FingerType) -> Bool {
        return isFingerPointing(finger, direction: .backward)
    }

    /// Determine if finger is pointing left
    /// - Parameter finger: Finger to evaluate
    /// - Returns: true if pointing left
    public func isFingerPointingLeft(_ finger: FingerType) -> Bool {
        return isFingerPointing(finger, direction: .left)
    }

    /// Determine if finger is pointing right
    /// - Parameter finger: Finger to evaluate
    /// - Returns: true if pointing right
    public func isFingerPointingRight(_ finger: FingerType) -> Bool {
        return isFingerPointing(finger, direction: .right)
    }

    // MARK: - Helper Functions

    /// Get list of finger joints
    private func getFingerJoints(_ finger: FingerType) -> [HandSkeleton.JointName] {
        switch finger {
        case .thumb:
            // Thumb has fewer joints, so use from knuckle to tip
            return [.thumbKnuckle, .thumbIntermediateTip, .thumbTip]
        case .index:
            // Index finger uses from knuckle to tip (reduce intermediate joints for stability)
            return [.indexFingerKnuckle, .indexFingerIntermediateTip, .indexFingerTip]
        case .middle:
            // Middle finger uses from knuckle to tip (reduce intermediate joints for stability)
            return [.middleFingerKnuckle, .middleFingerIntermediateTip, .middleFingerTip]
        case .ring:
            // Ring finger uses from knuckle to tip (reduce intermediate joints for stability)
            return [.ringFingerKnuckle, .ringFingerIntermediateTip, .ringFingerTip]
        case .little:
            // Little finger uses from knuckle to tip (reduce intermediate joints for stability)
            return [.littleFingerKnuckle, .littleFingerIntermediateTip, .littleFingerTip]
        }
    }

    /// Get fingertip joint
    private func getFingerTipJoint(_ finger: FingerType) -> HandSkeleton.JointName {
        switch finger {
        case .thumb: return .thumbTip
        case .index: return .indexFingerTip
        case .middle: return .middleFingerTip
        case .ring: return .ringFingerTip
        case .little: return .littleFingerTip
        }
    }

    /// Calculate angle between three points (radians)
    private func calculateAngleBetweenPoints(p1: SIMD3<Float>, p2: SIMD3<Float>, p3: SIMD3<Float>)
        -> Float
    {
        // Calculate two vectors
        let v1 = normalize(p1 - p2)
        let v2 = normalize(p3 - p2)

        // Calculate cosine from dot product
        let cosine = simd_dot(v1, v2)

        // Get angle (radians) using arccosine
        // Limit to -1.0 to 1.0 range to prevent numerical errors
        return acos(max(-1.0, min(1.0, cosine)))
    }

    /// Get the direction a specific finger is pointing
    /// - Parameter finger: Finger to get direction for
    /// - Returns: Finger direction
    public func getPointingDirection(for finger: FingerType) -> PalmDirection {
        // Get fingertip and joint positions
        let tipJoint: HandSkeleton.JointName
        let middleJoint: HandSkeleton.JointName

        switch finger {
        case .thumb:
            tipJoint = .thumbTip
            middleJoint = .thumbIntermediateTip
        case .index:
            tipJoint = .indexFingerTip
            middleJoint = .indexFingerIntermediateTip
        case .middle:
            tipJoint = .middleFingerTip
            middleJoint = .middleFingerIntermediateTip
        case .ring:
            tipJoint = .ringFingerTip
            middleJoint = .ringFingerIntermediateTip
        case .little:
            tipJoint = .littleFingerTip
            middleJoint = .littleFingerIntermediateTip
        }

        // Get fingertip and joint positions
        guard let tipEntity = fingers[tipJoint] else { return .backward }
        guard let middleEntity = fingers[middleJoint] else { return .backward }

        // Calculate finger direction vector
        let tipPosition = tipEntity.position(relativeTo: nil)
        let middlePosition = middleEntity.position(relativeTo: nil)
        let directionVector = normalize(tipPosition - middlePosition)

        // Determine closest direction from direction vector
        return getDirectionFromNormal(directionVector)
    }

    // MARK: - 5. Fingertip Distance Detection

    /// Determine if two fingertips are sufficiently separated
    /// - Parameters:
    ///   - fingerA: First finger
    ///   - fingerB: Second finger
    ///   - minSpacing: Minimum spacing (meters). Default is 1.5cm
    /// - Returns: true if fingertips are separated by at least the minimum spacing
    public func areTwoFingersSeparated(
        _ fingerA: FingerType, _ fingerB: FingerType, minSpacing: Float = 0.03
    ) -> Bool {
        let tipJointA = getFingerTipJoint(fingerA)
        let tipJointB = getFingerTipJoint(fingerB)

        guard let tipEntityA = fingers[tipJointA],
            let tipEntityB = fingers[tipJointB]
        else {
            return false
        }

        let tipPosA = tipEntityA.position(relativeTo: nil)
        let tipPosB = tipEntityB.position(relativeTo: nil)

        let distance = simd_distance(tipPosA, tipPosB)
        return distance >= minSpacing
    }
}
