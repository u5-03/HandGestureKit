//
//  CommonGesturePatterns.swift
//  HandGesturePackage
//
//  Created by Claude Code on 2025/07/24.
//

import Foundation

/// Factory for frequently used gesture patterns
public enum CommonGesturePatterns {

    /// Create peace sign builder
    public static func peaceSign() -> GestureBuilder {
        return GestureBuilder()
            .withStraightFingers(.index, .middle)
            .withBentFingers(.thumb, .ring, .little)
            .withFingerPointing(.index, direction: .top)
            .withFingerPointing(.middle, direction: .top)
            .withPalmFacing(.forward)
    }

    /// Create thumbs up builder
    public static func thumbsUp() -> GestureBuilder {
        return GestureBuilder()
            .withStraightFingers(.thumb)
            .withBentFingers(.index, .middle, .ring, .little)
            .withFingerPointing(.thumb, direction: .top)
    }

    /// Create pointing builder
    public static func pointing() -> GestureBuilder {
        return GestureBuilder()
            .withStraightFingers(.index)
            .withBentFingers(.thumb, .middle, .ring, .little)
    }

    /// Create fist builder
    public static func fist() -> GestureBuilder {
        return GestureBuilder()
            .withBentFingers(.thumb, .index, .middle, .ring, .little)
    }

    /// Create open hand (paper) builder
    public static func openHand() -> GestureBuilder {
        return GestureBuilder()
            .withStraightFingers(.thumb, .index, .middle, .ring, .little)
    }

    /// Fist + extend specific finger pattern (used for sign language I, etc.)
    public static func fistWithExtendedFinger(_ extendedFinger: FingerType) -> GestureBuilder {
        var bentFingers: [FingerType] = [.thumb, .index, .middle, .ring, .little]
        bentFingers.removeAll { $0 == extendedFinger }

        return GestureBuilder()
            .withStraightFingers(extendedFinger)
            .withBentFingers(bentFingers[0], bentFingers[1], bentFingers[2], bentFingers[3])
    }

    /// Multiple extended fingers pattern (used for sign language W, L, etc.)
    public static func extendedFingers(_ fingers: FingerType...) -> GestureBuilder {
        let allFingers: [FingerType] = [.thumb, .index, .middle, .ring, .little]
        let bentFingers = allFingers.filter { !fingers.contains($0) }

        var builder = GestureBuilder()

        // Set fingers to extend
        for finger in fingers {
            builder = builder.withStraightFingers(finger)
        }

        // Set fingers to bend
        for finger in bentFingers {
            builder = builder.withBentFingers(finger)
        }

        return builder
    }

    /// Flat hand (used for sign language B, etc.) - thumb touches palm
    public static func flatHand() -> GestureBuilder {
        return GestureBuilder()
            .withStraightFingers(.index, .middle, .ring, .little)
            .withBentFingers(.thumb)
    }

    /// Horizontal pointing (used for sign language G, etc.)
    public static func horizontalPointing(_ pointingFinger: FingerType = .index) -> GestureBuilder {
        var bentFingers: [FingerType] = [.thumb, .index, .middle, .ring, .little]
        bentFingers.removeAll { $0 == pointingFinger }

        return GestureBuilder()
            .withStraightFingers(pointingFinger)
            .withBentFingers(bentFingers[0], bentFingers[1], bentFingers[2], bentFingers[3])
    }
}
