import XCTest
@testable import SwipeActions

final class SwipeMotionTests: XCTestCase {
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
