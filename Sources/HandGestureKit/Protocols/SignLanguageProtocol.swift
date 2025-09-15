//
//  SignLanguageProtocol.swift
//  HandGestureKit
//
//  Created by Yugo Sugiyama on 2025/07/30.
//

import Foundation

/// Protocol for defining sign language gestures
public protocol SignLanguageProtocol: SingleHandGestureProtocol {
    /// Text representing the meaning of the sign language
    var meaning: String { get }
}

/// Default implementation
extension SignLanguageProtocol {

    /// Default priority (set high to prioritize over regular gestures)
    public var priority: Int { 10 }
}
