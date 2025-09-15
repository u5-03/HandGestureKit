# HandGestureKit

A powerful and extensible hand gesture detection framework for visionOS, providing declarative gesture definition and real-time hand tracking capabilities.

## Features

- 🎯 **Declarative Gesture Definition** - Define gestures using simple, composable conditions
- 🚀 **High Performance** - Optimized detection with early-return patterns and priority-based searching
- 🔧 **Extensible Architecture** - Protocol-based design for easy custom gesture creation
- 📱 **visionOS 2.0+ Support** - Built for Apple Vision Pro with ARKit hand tracking
- 🎨 **Built-in Gesture Library** - Common gestures like peace sign, thumbs up, pointing, etc.

## Requirements

- visionOS 2.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add HandGestureKit to your project through Xcode:

1. File → Add Package Dependencies
2. Enter the repository URL
3. Select version and add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/HandGestureKit.git", from: "1.0.0")
]
```

## Quick Start

### 1. Import the Framework

```swift
import HandGestureKit
import RealityKit
```

### 2. Define a Custom Gesture

```swift
struct PeaceSignGesture: SingleHandGestureProtocol {
    var id: String { "peace_sign" }
    var displayName: String { "Peace Sign" }
    var gestureName: String { "PeaceSign" }
    var description: String { "Index and middle fingers extended" }
    var priority: Int { 100 }
    
    func matches(_ gestureData: SingleHandGestureData) -> Bool {
        // Check if index and middle fingers are straight
        guard gestureData.isFingerStraight(.index),
              gestureData.isFingerStraight(.middle) else {
            return false
        }
        
        // Check if other fingers are bent
        return gestureData.isFingerBent(.thumb) &&
               gestureData.isFingerBent(.ring) &&
               gestureData.isFingerBent(.little)
    }
}
```

### 3. Set Up Hand Tracking

```swift
struct HandTrackingView: View {
    var body: some View {
        RealityView { content in
            // Register the tracking system
            HandGestureTrackingSystem.registerSystem()
            
            // Set up hand tracking entities
            await setupHandTracking(content)
        }
    }
    
    private func setupHandTracking(_ content: RealityViewContent) async {
        // Request hand tracking permission
        let session = ARKitSession()
        await session.requestAuthorization(for: [.handTracking])
        
        // Start spatial tracking
        let spatialSession = SpatialTrackingSession()
        let config = SpatialTrackingSession.Configuration(tracking: [.hand])
        await spatialSession.run(config)
        
        // Create hand anchor entities...
    }
}
```

### 4. Detect Gestures

```swift
struct GestureDetectionSystem: System {
    static let query = EntityQuery(where: .has(HandTrackingComponent.self))
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let handComponent = entity.components[HandTrackingComponent.self] else { continue }
            
            // Create gesture data from hand tracking
            let gestureData = SingleHandGestureData(from: handComponent)
            
            // Check for gestures
            let peaceSign = PeaceSignGesture()
            if peaceSign.matches(gestureData) {
                print("Peace sign detected!")
            }
        }
    }
}
```

## Core Components

### Protocols

- **`BaseGestureProtocol`** - Base protocol for all gesture types
- **`SingleHandGestureProtocol`** - Protocol for single-hand gestures
- **`TwoHandsGestureProtocol`** - Protocol for two-hand gestures
- **`SignLanguageProtocol`** - Protocol for sign language gestures
- **`SerialGestureProtocol`** - Protocol for sequential gesture patterns

### Key Classes

- **`SingleHandGestureData`** - Encapsulates hand tracking data with convenience methods
- **`HandTrackingComponent`** - RealityKit component for hand tracking entities
- **`GestureDetector`** - Main gesture detection engine with priority-based matching

### Convenience Methods

SingleHandGestureData provides numerous helper methods:

```swift
// Finger state checks
gestureData.isFingerStraight(.index)     // Check if index finger is straight
gestureData.isFingerBent(.thumb)         // Check if thumb is bent
gestureData.areAllFingersStraight()      // Check if all fingers are straight

// Palm direction
gestureData.isPalmFacing(.forward)       // Check palm orientation
gestureData.isPalmFacing(.up)           

// Finger direction
gestureData.isFingerPointing(.index, direction: .forward)

// Complex conditions
gestureData.areAllFingersExceptBent([.index, .middle])  // All except specified are bent
```

## Advanced Usage

### Priority-Based Detection

Gestures are evaluated in priority order (lower values = higher priority):

```swift
struct HighPriorityGesture: SingleHandGestureProtocol {
    var priority: Int { 10 }  // Evaluated first
    // ...
}

struct LowPriorityGesture: SingleHandGestureProtocol {
    var priority: Int { 1000 }  // Evaluated last
    // ...
}
```

### Two-Hand Gestures

```swift
struct ClapGesture: TwoHandsGestureProtocol {
    func matches(_ gestureData: HandsGestureData) -> Bool {
        // Check if palms are facing each other
        guard gestureData.arePalmsFacingEachOther else { return false }
        
        // Check distance between palms
        return gestureData.palmDistance < 0.1  // Within 10cm
    }
}
```

### Performance Optimization

The framework includes several optimization strategies:

1. **Early Return Pattern** - Conditions are checked in order of selectivity
2. **Gesture Indexing** - Gestures are pre-sorted by priority
3. **Lazy Evaluation** - Complex calculations only when necessary
4. **Caching** - Results are cached within frame updates

## Example Project

Check out the `/Example` directory for a complete visionOS app demonstrating:

- Basic gesture detection
- Custom gesture creation
- Real-time visualization
- Performance monitoring

To run the example:

```bash
cd Example
open Package.swift  # Opens in Xcode
# Build and run for visionOS Simulator or Device
```

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Open `Package.swift` in Xcode
3. Build and test on visionOS simulator or device

### Running Tests

```bash
swift test
```

## License

HandGestureKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Acknowledgments

- Built for Apple Vision Pro and visionOS
- Inspired by natural human-computer interaction research
- Thanks to all contributors and the visionOS developer community

## Support

- 📧 Email: support@handgesturekit.dev
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/HandGestureKit/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/HandGestureKit/discussions)