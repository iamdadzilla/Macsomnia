import XCTest
@testable import MacsomniaCore

final class StateMonitorTests: XCTestCase {
    func testPollForwardsObservedValue() {
        var observed: [Bool] = []
        let monitor = StateMonitor(read: { true }, onObserved: { observed.append($0) })
        monitor.poll()
        XCTAssertEqual(observed, [true])
    }

    func testPollSkipsWhenReadReturnsNil() {
        var observed: [Bool] = []
        let monitor = StateMonitor(read: { nil }, onObserved: { observed.append($0) })
        monitor.poll()
        XCTAssertTrue(observed.isEmpty)
    }
}
