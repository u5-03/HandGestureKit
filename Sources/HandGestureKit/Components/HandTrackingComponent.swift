//
//  HandTrackingComponent.swift
//  HandGesturePackage
//
//  Created by yugo.sugiyama on 2025/06/05.
//

import Foundation
import RealityKit

#if os(visionOS)
    import ARKit
#endif

/// Component that holds hand tracking information
public struct HandTrackingComponent: Component {
    /// Indicates whether it's left or right hand
    public var chirality: HandAnchor.Chirality

    /// Dictionary holding entities for each joint
    public var fingers: [HandSkeleton.JointName: Entity] = [:]

    /// Dictionary holding entities for bones (connections between joints)
    public var bones: [HandSkeleton.JointName: ModelEntity] = [:]

    public init(chirality: HandAnchor.Chirality) {
        self.chirality = chirality
    }
}
