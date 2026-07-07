import XCTest
@testable import MacsomniaCore

final class MacsomniaDurationTests: XCTestCase {
    func testIntervals() {
        XCTAssertEqual(MacsomniaDuration.thirtyMinutes.timeInterval, 30 * 60)
        XCTAssertEqual(MacsomniaDuration.twoHours.timeInterval, 2 * 3600)
        XCTAssertEqual(MacsomniaDuration.fourHours.timeInterval, 4 * 3600)
        XCTAssertEqual(MacsomniaDuration.eightHours.timeInterval, 8 * 3600)
        XCTAssertNil(MacsomniaDuration.indefinite.timeInterval)
    }

    func testLabels() {
        XCTAssertEqual(MacsomniaDuration.thirtyMinutes.menuLabel, "30 minutes")
        XCTAssertEqual(MacsomniaDuration.twoHours.menuLabel, "2 hours")
        XCTAssertEqual(MacsomniaDuration.indefinite.menuLabel, "Until I turn it off")
    }

    func testMenuOrder() {
        XCTAssertEqual(MacsomniaDuration.allCases, [
            .thirtyMinutes, .twoHours, .fourHours, .eightHours, .indefinite
        ])
    }
}
