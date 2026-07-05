import XCTest
@testable import KeepAwakeCore

final class AppStateTests: XCTestCase {
    private var mock: MockPowerController!
    private var fixedNow: Date!
    private var state: AppState!

    override func setUp() {
        super.setUp()
        mock = MockPowerController()
        fixedNow = Date(timeIntervalSince1970: 1_000_000)
        state = AppState(power: mock, now: { self.fixedNow })
    }

    func testEnableTimedSetsStateAndExpiry() throws {
        try state.enable(.twoHours)
        XCTAssertTrue(state.isOn)
        XCTAssertTrue(state.initiatedByApp)
        XCTAssertEqual(mock.enableCount, 1)
        XCTAssertEqual(state.expiry, fixedNow.addingTimeInterval(2 * 3600))
    }

    func testEnableIndefiniteHasNoExpiry() throws {
        try state.enable(.indefinite)
        XCTAssertTrue(state.isOn)
        XCTAssertNil(state.expiry)
    }

    func testEnableArmsAutoOffCallback() throws {
        var armed: [Date?] = []
        state.onArmAutoOff = { armed.append($0) }
        try state.enable(.thirtyMinutes)
        XCTAssertEqual(armed, [fixedNow.addingTimeInterval(30 * 60)])
    }

    func testEnableFailureDoesNotFlipState() {
        struct Boom: Error {}
        mock.enableError = Boom()
        XCTAssertThrowsError(try state.enable(.twoHours))
        XCTAssertFalse(state.isOn)
        XCTAssertNil(state.expiry)
    }

    func testDisableByUserResetsAndCancelsAutoOff() throws {
        try state.enable(.twoHours)
        var armed: [Date?] = []
        state.onArmAutoOff = { armed.append($0) }
        try state.disableByUser()
        XCTAssertFalse(state.isOn)
        XCTAssertNil(state.expiry)
        XCTAssertEqual(mock.disableCount, 1)
        XCTAssertEqual(armed, [nil])
    }

    func testIsOnChangeFiresVisualCallback() throws {
        var visual: [Bool] = []
        state.onIsOnChanged = { visual.append($0) }
        try state.enable(.indefinite)
        try state.disableByUser()
        XCTAssertEqual(visual, [true, false])
    }
}
