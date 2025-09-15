//
//  TwoHandsGestureProtocol.swift
//  HandGesturePackage
//
//  Created by Claude on 2025/07/26.
//

import Foundation

/// Protocol for defining two-handed gestures
public protocol TwoHandsGestureProtocol: BaseGestureProtocol {

    /// Determine if two-handed gesture data matches this gesture
    /// - Parameter gestureData: Two-handed gesture data
    /// - Returns: true if the gesture matches
    func matches(_ gestureData: HandsGestureData) -> Bool
}

// MARK: - Default Implementation
extension TwoHandsGestureProtocol {
    public var description: String {
        return gestureName
    }

    public var priority: Int {
        return 0
    }

    public var gestureType: GestureType {
        return .twoHand
    }
}
