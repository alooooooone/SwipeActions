import Foundation

enum SwipeMotion {
    /// Starts with unit slope at the boundary, then progressively adds resistance.
    static func resistedDistance(_ distance: Double, power: Double) -> Double {
        let power = min(1, max(0.01, power))
        return 8 / power * (pow(1 + max(0, distance) / 8, power) - 1)
    }

    static func unresistedDistance(_ distance: Double, power: Double) -> Double {
        let power = min(1, max(0.01, power))
        return 8 * (pow(1 + max(0, distance) * power / 8, 1 / power) - 1)
    }

    /// Small fixed substeps keep the same spring stable at both 60 and 120 Hz.
    static func springStep(position: Double, velocity: Double, target: Double,
                           stiffness: Double, damping: Double, duration: Double) -> (position: Double, velocity: Double) {
        let steps = max(1, Int(ceil(duration * 240)))
        let dt = duration / Double(steps)
        var position = position
        var velocity = velocity
        for _ in 0..<steps {
            velocity += (-stiffness * (position - target) - damping * velocity) * dt
            position += velocity * dt
        }
        return (position, velocity)
    }

    static func acceptsHorizontalDrag(x: Double, y: Double, minimumDistance: Double = 8, ratio: Double = 1.5) -> Bool {
        abs(x) >= max(1, minimumDistance) && abs(x) > abs(y) * max(1, ratio)
    }

    static func rejectsVerticalDrag(x: Double, y: Double, ratio: Double = 1.5) -> Bool {
        abs(y) >= 4 && abs(x) <= abs(y) * max(1, ratio)
    }

    /// A cancelled drag or a drag returning to its starting point has no usable
    /// displacement for spring normalization. Never send NaN/infinity to SwiftUI.
    static func normalizedVelocity(_ velocity: Double, offset: Double) -> Double {
        guard velocity.isFinite, offset.isFinite, offset != 0 else { return 0 }
        let result = velocity / offset
        return result.isFinite ? result : 0
    }
}
