//
//  SerialGestureProtocol.swift
//  HandGestureKit
//
//  Created by Yugo Sugiyama on 2025/08/07.
//

import Foundation

/// Protocol for defining gestures with continuous motion
/// Expresses gestures with motion by detecting multiple gestures in sequence
public protocol SerialGestureProtocol: SignLanguageProtocol {
    /// Array of gestures to be detected in sequence
    var gestures: [BaseGestureProtocol] { get }

    /// Maximum allowable time between gestures (seconds)
    var intervalSeconds: TimeInterval { get }

    /// Description of each step (for UI display)
    var stepDescriptions: [String] { get }
}

/// Default implementation
extension SerialGestureProtocol {

    /// Default priority (set high)
    public var priority: Int { 5 }

    /// Default interval (1 second)
    public var intervalSeconds: TimeInterval { 1.0 }

    /// Default gesture type (serial gestures are typically two-handed)
    public var gestureType: GestureType { .twoHand }

    /// SingleHandGestureProtocol matches implementation (not used)
    public func matches(_ gestureData: SingleHandGestureData) -> Bool {
        // SerialGestureProtocol does not use individual matches methods
        // Instead, each element of the gestures property is matched in sequence
        return false
    }
}
