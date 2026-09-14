import SwiftUI
import UIKit

/// One presentation position drives the row, action layout, opacity and reveal mask.
/// No implicit animations: a new drag can take over the position actually on screen.
final class SwipePresentationMotion: ObservableObject {
    @Published private(set) var position = Double(0)
    private let positionTolerance: Double
    private let velocityTolerance: Double

    init(positionTolerance: Double = 0.1, velocityTolerance: Double = 1) {
        self.positionTolerance = positionTolerance
        self.velocityTolerance = velocityTolerance
    }

    private var velocity = Double(0)
    private var target = Double(0)
    private var stiffness = Double(90)
    private var damping = Double(20)
    private var lastTrackTime: CFTimeInterval?
    private var lastFrameTime: CFTimeInterval?
    private var displayLink: CADisplayLink?

    private final class TickTarget: NSObject {
        weak var owner: SwipePresentationMotion?
        @objc func tick(_ link: CADisplayLink) { owner?.tick(link) }
    }
    private let tickTarget = TickTarget()

    deinit { displayLink?.invalidate() }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastFrameTime = nil
        lastTrackTime = nil
        velocity = 0
    }

    func track(_ position: Double) {
        let now = CACurrentMediaTime()
        if let previous = lastTrackTime, now - previous > 0.001 {
            velocity = (position - self.position) / (now - previous)
        }
        lastTrackTime = now
        publish(position)
    }

    func settle(to target: Double, stiffness: Double, damping: Double) {
        // State/group notifications can request the same close more than once.
        guard displayLink == nil || self.target != target else { return }
        self.target = target
        self.stiffness = max(1, stiffness)
        self.damping = max(1, damping)
        if let lastTrackTime, CACurrentMediaTime() - lastTrackTime > 0.08 { velocity = 0 }
        velocity = min(900, max(-900, velocity))
        lastTrackTime = nil
        if displayLink == nil {
            tickTarget.owner = self
            let link = CADisplayLink(target: tickTarget, selector: #selector(TickTarget.tick(_:)))
            lastFrameTime = CACurrentMediaTime()
            displayLink = link
            link.add(to: .main, forMode: .common)
        }
    }

    private func tick(_ link: CADisplayLink) {
        let dt = min(1.0 / 30, max(0, link.timestamp - (lastFrameTime ?? link.timestamp)))
        lastFrameTime = link.timestamp
        let sample = SwipeMotion.springStep(position: position, velocity: velocity, target: target,
                                             stiffness: stiffness, damping: damping, duration: dt)
        velocity = sample.velocity
        if abs(sample.position - target) < positionTolerance && abs(velocity) < velocityTolerance {
            publish(target)
            stop()
        } else {
            publish(sample.position)
        }
    }

    private func publish(_ value: Double) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) { position = value }
    }
}
