import SwiftUI
import UIKit

/// Shared samples keep the existing layout/state machine independent of its recognizer.
struct SwipeDragValue {
    let translation: CGSize
    let predictedEndTranslation: CGSize
    let location: CGPoint
    let startLocation: CGPoint

    init(_ value: DragGesture.Value) {
        translation = value.translation
        predictedEndTranslation = value.predictedEndTranslation
        location = value.location
        startLocation = value.startLocation
    }

    init(translation: CGPoint, velocity: CGPoint) {
        self.translation = CGSize(width: translation.x, height: translation.y)
        // A short, bounded projection avoids opening the opposite side on a quick reversal.
        predictedEndTranslation = CGSize(width: translation.x + min(60, max(-60, velocity.x * 0.08)),
                                         height: translation.y)
        location = translation
        startLocation = .zero
    }
}

struct SwipeHorizontalPanModifier: ViewModifier {
    let enabled: Bool
    let minimumDistance: Double
    let intentRatio: Double
    let onChange: (SwipeDragValue) -> Void
    let onEnd: (SwipeDragValue) -> Void
    let onCancel: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), enabled {
            content.gesture(SwipeHorizontalPan(minimumDistance: minimumDistance, intentRatio: intentRatio,
                                              onChange: onChange, onEnd: onEnd, onCancel: onCancel))
        } else {
            content
        }
    }
}

@available(iOS 18.0, *)
private struct SwipeHorizontalPan: UIGestureRecognizerRepresentable {
    let minimumDistance: Double
    let intentRatio: Double
    let onChange: (SwipeDragValue) -> Void
    let onEnd: (SwipeDragValue) -> Void
    let onCancel: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(minimumDistance: minimumDistance, intentRatio: intentRatio)
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = DirectionalPan()
        pan.minimumDistance = max(1, minimumDistance)
        pan.intentRatio = intentRatio
        pan.delegate = context.coordinator
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = true
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.minimumDistance = minimumDistance
        context.coordinator.intentRatio = intentRatio
        (recognizer as? DirectionalPan)?.minimumDistance = max(1, minimumDistance)
        (recognizer as? DirectionalPan)?.intentRatio = intentRatio
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view)
        let velocity = recognizer.velocity(in: recognizer.view)
        let sample = SwipeDragValue(translation: translation, velocity: velocity)
        switch recognizer.state {
        case .began, .changed: onChange(sample)
        case .ended: onEnd(sample)
        case .cancelled, .failed: onCancel()
        default: break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var minimumDistance: Double
        var intentRatio: Double

        init(minimumDistance: Double, intentRatio: Double) {
            self.minimumDistance = minimumDistance
            self.intentRatio = intentRatio
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            // UIPan's translation has already deducted its recognition slop here.
            // Use total travel from touch-down so the threshold is applied only once.
            let translation = (pan as? DirectionalPan)?.intentTranslation ?? pan.translation(in: pan.view)
            return SwipeMotion.acceptsHorizontalDrag(x: translation.x, y: translation.y,
                                                      minimumDistance: minimumDistance, ratio: intentRatio)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // The ancestor scroll pan waits only until horizontal intent is accepted/rejected.
            guard let scrollView = otherGestureRecognizer.view as? UIScrollView else { return false }
            // SwiftUI may attach a representable recognizer above the virtual row's host.
            // UIKit only asks about recognizers participating in this same touch sequence.
            return otherGestureRecognizer === scrollView.panGestureRecognizer
        }
    }

    final class DirectionalPan: UIPanGestureRecognizer {
        private var origin: CGPoint?
        var intentTranslation = CGPoint.zero
        var minimumDistance = Double(8)
        var intentRatio = Double(1.5)

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            if origin == nil { origin = touches.first?.location(in: view) }
            super.touchesBegan(touches, with: event)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            if state == .possible, let origin, let location = touches.first?.location(in: view) {
                let x = location.x - origin.x
                let y = location.y - origin.y
                intentTranslation = CGPoint(x: x, y: y)
                if SwipeMotion.rejectsVerticalDrag(x: x, y: y, ratio: intentRatio) {
                    state = .failed
                    return
                }
                if abs(x) < minimumDistance { return }
            }
            super.touchesMoved(touches, with: event)
        }

        override func reset() {
            super.reset()
            origin = nil
            intentTranslation = .zero
        }
    }
}
