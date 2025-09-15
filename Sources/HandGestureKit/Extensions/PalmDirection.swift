import Foundation
import simd

/// Enumeration representing palm direction
public enum PalmDirection: String, CaseIterable {
    case up
    case down
    case left
    case right
    case forward
    case backward
    case unknown

    /// Unit vector representing direction
    public var vector: SIMD3<Float> {
        switch self {
        case .up:
            return SIMD3<Float>(0, 1, 0)  // Y+
        case .down:
            return SIMD3<Float>(0, -1, 0) // Y-
        case .left:
            return SIMD3<Float>(-1, 0, 0) // X-
        case .right:
            return SIMD3<Float>(1, 0, 0)  // X+
        case .forward:
            return SIMD3<Float>(0, 0, -1) // Z-
        case .backward:
            return SIMD3<Float>(0, 0, 1)  // Z+
        case .unknown:
            return SIMD3<Float>(0, 0, 0)  // Unknown
        }
    }

    /// Direction description
    public var description: String {
        switch self {
        case .up:
            return "Up"
        case .down:
            return "Down"
        case .left:
            return "Left"
        case .right:
            return "Right"
        case .forward:
            return "Forward"
        case .backward:
            return "Backward"
        case .unknown:
            return "Unknown"
        }
    }
}