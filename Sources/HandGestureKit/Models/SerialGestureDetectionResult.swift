//
//  SerialGestureDetectionResult.swift
//  HandGestureKit
//
//  Created by Yugo Sugiyama on 2025/08/07.
//

import Foundation

/// Enumeration representing the detection result of serial gestures
public enum SerialGestureDetectionResult {
    /// In progress (includes current index and total gesture count)
    case progress(currentIndex: Int, totalGestures: Int, gesture: SerialGestureProtocol)

    /// Completed (all gestures matched)
    case completed(gesture: SerialGestureProtocol)

    /// Timeout (exceeded interval)
    case timeout

    /// Not matched (current gesture differs from expected)
    case notMatched

    /// Get progress percentage
    public var progressPercentage: Float {
        switch self {
        case .progress(let current, let total, _):
            guard total > 0 else { return 0 }
            return Float(current) / Float(total)
        case .completed:
            return 1.0
        default:
            return 0
        }
    }

    /// Get current step number (1-based)
    public var currentStep: Int {
        switch self {
        case .progress(let current, _, _):
            return current + 1
        case .completed(let gesture):
            return gesture.gestures.count
        default:
            return 0
        }
    }

    /// Get total number of steps
    public var totalSteps: Int {
        switch self {
        case .progress(_, let total, _):
            return total
        case .completed(let gesture):
            return gesture.gestures.count
        default:
            return 0
        }
    }
}
