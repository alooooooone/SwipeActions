import SwiftUI
import XCTest
@testable import SwipeActions

final class SwipeMotionTests: XCTestCase {
    func testActionVerticalOverflowDefaultsToZeroAndClampsNegativeValues() {
        let swipeView = SwipeView {
            EmptyView()
        } leadingActions: { _ in
            EmptyView()
        } trailingActions: { _ in
            EmptyView()
        }

        XCTAssertEqual(swipeView.options.actionsTopOverflow, 0)
        XCTAssertEqual(swipeView.options.actionsBottomOverflow, 0)

        let clamped = swipeView.swipeActionsVerticalOverflow(top: -1, bottom: -2)
        XCTAssertEqual(clamped.options.actionsTopOverflow, 0)
        XCTAssertEqual(clamped.options.actionsBottomOverflow, 0)

        let configured = swipeView.swipeActionsVerticalOverflow(top: 1, bottom: 2)
        XCTAssertEqual(configured.options.actionsTopOverflow, 1)
        XCTAssertEqual(configured.options.actionsBottomOverflow, 2)
    }

    func testOvershootCanBeTakenOverWithoutApplyingResistanceTwice() {
        for position in [0.0, 0.5, 8, 40, 100] {
            let origin = SwipeMotion.unresistedDistance(position, power: 0.5)
            XCTAssertEqual(SwipeMotion.resistedDistance(origin, power: 0.5), position, accuracy: 0.00001)
        }
    }

    func testResistanceHasNoVelocityKinkAtBoundary() {
        XCTAssertEqual(SwipeMotion.resistedDistance(0, power: 0.5), 0)
        XCTAssertEqual(SwipeMotion.resistedDistance(0.001, power: 0.5) / 0.001, 1, accuracy: 0.001)
        XCTAssertLessThan(SwipeMotion.resistedDistance(100, power: 0.5), 100)
    }

    func testSpringConvergesWithoutJumpingAndIsFrameRateIndependent() {
        func simulate(hz: Double) -> Double {
            var position = 35.0
            var velocity = 0.0
            for _ in 0..<Int(hz) {
                let sample = SwipeMotion.springStep(position: position, velocity: velocity, target: 92,
                                                     stiffness: 90, damping: 20, duration: 1 / hz)
                XCTAssertGreaterThanOrEqual(sample.position, position)
                XCTAssertLessThanOrEqual(sample.position, 92)
                XCTAssertLessThan(sample.position - position, 5)
                (position, velocity) = sample
            }
            return position
        }
        XCTAssertEqual(simulate(hz: 60), simulate(hz: 120), accuracy: 0.01)
        XCTAssertEqual(simulate(hz: 60), 92, accuracy: 0.5)
    }

    func testRetargetAndInterruptionPreservePresentationPosition() {
        let motion = SwipePresentationMotion()
        motion.track(35)
        motion.settle(to: 92, stiffness: 90, damping: 20)
        XCTAssertEqual(motion.position, 35)
        motion.settle(to: 0, stiffness: 90, damping: 20)
        XCTAssertEqual(motion.position, 35)
        motion.stop()
        motion.track(34)
        XCTAssertEqual(motion.position, 34)
    }

    func testVerticalAndDiagonalIntentFailsBeforeRecognition() {
        for (x, y) in [(0.0, 4.0), (3, 8), (-5, -10), (10, 10), (-10, 10)] {
            XCTAssertTrue(SwipeMotion.rejectsVerticalDrag(x: x, y: y))
            XCTAssertFalse(SwipeMotion.acceptsHorizontalDrag(x: x, y: y))
        }
    }

    func testDeliberateHorizontalIntentWorksInBothDirections() {
        for (x, y) in [(8.0, 0.0), (14, 4), (-14, -4), (20, 10)] {
            XCTAssertFalse(SwipeMotion.rejectsVerticalDrag(x: x, y: y))
            XCTAssertTrue(SwipeMotion.acceptsHorizontalDrag(x: x, y: y))
        }
        XCTAssertFalse(SwipeMotion.acceptsHorizontalDrag(x: 5, y: 0))
        XCTAssertFalse(SwipeMotion.acceptsHorizontalDrag(x: 14, y: 10, ratio: 1.5))
        XCTAssertTrue(SwipeMotion.acceptsHorizontalDrag(x: 14, y: 10, ratio: 1.2))
    }

    func testReturningToOriginUsesFiniteSpringVelocity() {
        XCTAssertEqual(SwipeMotion.normalizedVelocity(120, offset: 0), 0)
        XCTAssertEqual(SwipeMotion.normalizedVelocity(0, offset: 0), 0)
    }

    func testInvalidSamplesAndOverflowUseFiniteSpringVelocity() {
        XCTAssertEqual(SwipeMotion.normalizedVelocity(.infinity, offset: 20), 0)
        XCTAssertEqual(SwipeMotion.normalizedVelocity(.nan, offset: 20), 0)
        XCTAssertEqual(SwipeMotion.normalizedVelocity(100, offset: .nan), 0)
        XCTAssertEqual(SwipeMotion.normalizedVelocity(.greatestFiniteMagnitude, offset: .leastNonzeroMagnitude), 0)
    }

    func testNormalDragPreservesDirectionAndVelocity() {
        XCTAssertEqual(SwipeMotion.normalizedVelocity(120, offset: 30), 4)
        XCTAssertEqual(SwipeMotion.normalizedVelocity(-120, offset: 30), -4)
        XCTAssertEqual(SwipeMotion.normalizedVelocity(-120, offset: -30), 4)
    }
}
