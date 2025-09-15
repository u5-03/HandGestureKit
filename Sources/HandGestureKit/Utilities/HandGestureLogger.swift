//
//  HandGestureLogger.swift
//  HandGesturePackage
//
//  Created by Assistant on 2024/12/10.
//

import Foundation
import os

/// Logger for the hand gesture package
public enum HandGestureLogger {

    // MARK: - Debug Control

    /// Single flag to control debug log output
    public static var isDebugEnabled = true

    // MARK: - Logger Categories

    /// System-related logs
    public static let system = Logger(subsystem: "com.handgesture.package", category: "system")

    /// Gesture detection-related logs
    public static let gesture = Logger(subsystem: "com.handgesture.package", category: "gesture")

    /// Performance-related logs
    public static let performance = Logger(
        subsystem: "com.handgesture.package", category: "performance")

    /// UI-related logs
    public static let ui = Logger(subsystem: "com.handgesture.package", category: "ui")

    /// Debug logs
    public static let debug = Logger(subsystem: "com.handgesture.package", category: "debug")

    // MARK: - Configuration

    /// Log output configuration
    public struct Configuration {
        /// Whether to output system logs
        public var enableSystemLogs = true

        /// Whether to output gesture detection logs
        public var enableGestureLogs = true

        /// Whether to output performance logs
        public var enablePerformanceLogs = true

        /// Whether to output UI logs
        public var enableUILogs = true

        /// Whether to output debug logs
        public var enableDebugLogs = true

        /// Disable all logs
        public mutating func disableAll() {
            enableSystemLogs = false
            enableGestureLogs = false
            enablePerformanceLogs = false
            enableUILogs = false
            enableDebugLogs = false
        }

        /// Enable all logs
        public mutating func enableAll() {
            enableSystemLogs = true
            enableGestureLogs = true
            enablePerformanceLogs = true
            enableUILogs = true
            enableDebugLogs = true
        }
    }

    /// Current log configuration
    public static var configuration = Configuration() {
        didSet {
            // Sync with isDebugEnabled flag
            configuration.enableDebugLogs = isDebugEnabled
        }
    }

    // MARK: - Convenience Methods

    /// Output system log
    public static func logSystem(_ message: String, type: OSLogType = .info) {
        guard configuration.enableSystemLogs else { return }
        system.log(level: type, "\(message)")
    }

    /// Output gesture detection log
    public static func logGesture(_ message: String, type: OSLogType = .info) {
        guard configuration.enableGestureLogs else { return }
        gesture.log(level: type, "\(message)")
    }

    /// Output performance log
    public static func logPerformance(_ message: String, type: OSLogType = .info) {
        guard configuration.enablePerformanceLogs else { return }
        performance.log(level: type, "\(message)")
    }

    /// Output UI log
    public static func logUI(_ message: String, type: OSLogType = .info) {
        guard configuration.enableUILogs else { return }
        ui.log(level: type, "\(message)")
    }

    /// Output debug log
    public static func logDebug(_ message: String, type: OSLogType = .debug) {
        guard isDebugEnabled else { return }
        debug.log(level: type, "\(message)")
    }

    /// Output error log (always output)
    public static func logError(_ message: String, error: Error? = nil) {
        if let error = error {
            system.error("❌ \(message): \(error.localizedDescription)")
        } else {
            system.error("❌ \(message)")
        }
    }
}
