import XCTest
@testable import KeepAwakeCore

final class KeepAwakeDurationTests: XCTestCase {
    func testIntervals() {
        XCTAssertEqual(KeepAwakeDuration.thirtyMinutes.timeInterval, 30 * 60)
        XCTAssertEqual(KeepAwakeDuration.twoHours.timeInterval, 2 * 3600)
        XCTAssertEqual(KeepAwakeDuration.fourHours.timeInterval, 4 * 3600)
        XCTAssertEqual(KeepAwakeDuration.eightHours.timeInterval, 8 * 3600)
        XCTAssertNil(KeepAwakeDuration.indefinite.timeInterval)
    }

    func testLabels() {
        XCTAssertEqual(KeepAwakeDuration.thirtyMinutes.menuLabel, "30 minutes")
        XCTAssertEqual(KeepAwakeDuration.twoHours.menuLabel, "2 hours")
        XCTAssertEqual(KeepAwakeDuration.indefinite.menuLabel, "Until I turn it off")
    }

    func testMenuOrder() {
        XCTAssertEqual(KeepAwakeDuration.allCases, [
            .thirtyMinutes, .twoHours, .fourHours, .eightHours, .indefinite
        ])
    }
}
