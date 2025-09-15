//
//  BaseGestureProtocol.swift
//  HandGesturePackage
//
//  Created by Yugo Sugiyama on 2025/07/26.
//

import Foundation

/// Base protocol for all gesture types
public protocol BaseGestureProtocol {
    /// Unique identifier for the gesture
    var id: String { get }

    /// Display name for the gesture
    var displayName: String { get }

    /// Gesture name for identification
    var gestureName: String { get }

    /// Description of the gesture
    var description: String { get }

    /// Gesture priority (lower value means higher priority)
    var priority: Int { get }

    /// Gesture type (single hand or two hands)
    var gestureType: GestureType { get }
}

/// Type of gesture
public enum GestureType {
    case singleHand
    case twoHand
}

/// Gesture detection result
public enum GestureDetectionResult {
    case success([DetectedGesture])
    case failure(GestureDetectionError)
}

/// Information about detected gesture
public struct DetectedGesture {
    public let gesture: BaseGestureProtocol
    public let confidence: Float
    public let metadata: [String: Any]

    public init(
        gesture: BaseGestureProtocol, confidence: Float = 1.0, metadata: [String: Any] = [:]
    ) {
        self.gesture = gesture
        self.confidence = confidence
        self.metadata = metadata
    }
}

/// Gesture detection error
public enum GestureDetectionError: Error, LocalizedError {
    case noHandDataAvailable
    case invalidHandData(String)
    case processingError(String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .noHandDataAvailable:
            return "Hand data is not available"
        case .invalidHandData(let detail):
            return "Invalid hand data: \(detail)"
        case .processingError(let detail):
            return "Processing error: \(detail)"
        case .timeout:
            return "Timeout occurred"
        }
    }
}

/// Default implementation
extension BaseGestureProtocol {
    /// Default id implementation (using type name)
    public var id: String {
        // Remove module name from type name to use as ID
        let fullTypeName = String(describing: type(of: self))
        return fullTypeName.split(separator: ".").last.map(String.init) ?? fullTypeName
    }

    /// Default displayName implementation (using gestureName)
    public var displayName: String {
        return gestureName
    }

    public var description: String {
        return gestureName
    }

}
