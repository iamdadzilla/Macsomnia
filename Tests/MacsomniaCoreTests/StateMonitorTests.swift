import XCTest
@testable import MacsomniaCore

final class StateMonitorTests: XCTestCase {
    func testPollForwardsObservedValue() {
        let exp = expectation(description: "observed")
        var observed: [Bool] = []
        let monitor = StateMonitor(read: { true }, onObserved: { observed.append($0); exp.fulfill() })
        monitor.poll()
        wait(for: [exp], timeout: 2)
        XCTAssertEqual(observed, [true])
    }

    func testPollSkipsWhenReadReturnsNil() {
        let exp = expectation(description: "should not observe")
        exp.isInverted = true
        let monitor = StateMonitor(read: { nil }, onObserved: { _ in exp.fulfill() })
        monitor.poll()
        wait(for: [exp], timeout: 0.3)
    }

    /// `read()` can block (synchronous XPC to the privileged helper). `poll()`
    /// must run it off the caller's thread — otherwise a slow/unreachable helper
    /// blocks the main run loop at launch and the menu-bar item never appears.
    func testPollDoesNotBlockCaller() {
        let exp = expectation(description: "observed")
        let monitor = StateMonitor(
            read: { Thread.sleep(forTimeInterval: 0.5); return true },
            onObserved: { _ in exp.fulfill() }
        )
        let start = Date()
        monitor.poll()
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 0.1, "poll() must not block its caller while read() runs")
        wait(for: [exp], timeout: 2)
    }
}
