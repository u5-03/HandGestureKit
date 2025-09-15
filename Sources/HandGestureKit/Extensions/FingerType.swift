import Foundation

/// Enumeration representing finger types
public enum FingerType: CaseIterable {
    case thumb  // Thumb
    case index  // Index finger
    case middle  // Middle finger
    case ring  // Ring finger
    case little  // Little finger

    /// Finger name (English)
    public var description: String {
        switch self {
        case .thumb:
            return "Thumb"
        case .index:
            return "Index"
        case .middle:
            return "Middle"
        case .ring:
            return "Ring"
        case .little:
            return "Little"
        }
    }

    /// Short finger name (for distance display)
    public var shortDescription: String {
        switch self {
        case .thumb:
            return "T"
        case .index:
            return "I"
        case .middle:
            return "M"
        case .ring:
            return "R"
        case .little:
            return "L"
        }
    }
}
