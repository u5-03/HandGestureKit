//
//  SearchStats.swift
//  HandGesturePackage
//
//  Created by Yugo Sugiyama on 2025/07/27.
//

import Foundation

/// Statistical information for gesture search
public struct SearchStats {
    /// Number of search executions
    public var searchCount = 0

    /// Total number of gestures checked
    public var gesturesChecked = 0

    /// Total number of matches found
    public var matchesFound = 0

    /// Total search time (seconds)
    public var totalSearchTime = 0.0

    /// Average search time (seconds)
    public var averageSearchTime: TimeInterval {
        return searchCount > 0 ? totalSearchTime / Double(searchCount) : 0.0
    }

    /// Average check efficiency (match rate)
    public var matchRate: Double {
        return gesturesChecked > 0 ? Double(matchesFound) / Double(gesturesChecked) : 0.0
    }

    public init() {}
}

// MARK: - Formatting Extensions

extension SearchStats {
    /// Get formatted statistical information
    public var formattedSummary: String {
        """
        Searches: \(searchCount)
        Checked: \(gesturesChecked)
        Matches: \(matchesFound)
        Avg Time: \(String(format: "%.3f", averageSearchTime * 1000))ms
        Match Rate: \(String(format: "%.1f", matchRate * 100))%
        """
    }

    /// Determine performance level
    public enum PerformanceLevel {
        case excellent  // < 5ms
        case good  // < 10ms
        case fair  // < 20ms
        case poor  // >= 20ms

        var description: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Needs Improvement"
            }
        }
    }

    /// Current performance level
    public var performanceLevel: PerformanceLevel {
        let avgTimeMs = averageSearchTime * 1000
        if avgTimeMs < 5 {
            return .excellent
        } else if avgTimeMs < 10 {
            return .good
        } else if avgTimeMs < 20 {
            return .fair
        } else {
            return .poor
        }
    }
}
