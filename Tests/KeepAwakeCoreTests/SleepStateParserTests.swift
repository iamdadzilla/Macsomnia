import XCTest
@testable import KeepAwakeCore

final class SleepStateParserTests: XCTestCase {
    func testParsesDisabledTrue() {
        let output = """
         System-wide power settings:
         SleepDisabled          1
         Currently in use:
         standby              1
        """
        XCTAssertEqual(SleepStateParser.sleepDisabled(fromPmsetOutput: output), true)
    }

    func testParsesDisabledFalse() {
        let output = " SleepDisabled          0\n standby              1\n"
        XCTAssertEqual(SleepStateParser.sleepDisabled(fromPmsetOutput: output), false)
    }

    func testReturnsNilWhenMissing() {
        let output = " standby              1\n hibernatemode 3\n"
        XCTAssertNil(SleepStateParser.sleepDisabled(fromPmsetOutput: output))
    }
}
