import XCTest
@testable import MacsomniaCore

final class CountdownTests: XCTestCase {
    func testHoursAndMinutes() {
        XCTAssertEqual(Countdown.format(remaining: 3 * 3600 + 59 * 60), "3:59")
    }

    func testUnderOneHourPadsMinutes() {
        XCTAssertEqual(Countdown.format(remaining: 45 * 60), "0:45")
    }

    func testRoundsUpPartialMinute() {
        XCTAssertEqual(Countdown.format(remaining: 30), "0:01")
    }

    func testZeroAndNegativeClampToZero() {
        XCTAssertEqual(Countdown.format(remaining: 0), "0:00")
        XCTAssertEqual(Countdown.format(remaining: -120), "0:00")
    }
}
