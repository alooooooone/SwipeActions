import Foundation

enum SwipeMotion {
    /// A cancelled drag or a drag returning to its starting point has no usable
    /// displacement for spring normalization. Never send NaN/infinity to SwiftUI.
    static func normalizedVelocity(_ velocity: Double, offset: Double) -> Double {
        guard velocity.isFinite, offset.isFinite, offset != 0 else { return 0 }
        let result = velocity / offset
        return result.isFinite ? result : 0
    }
}
