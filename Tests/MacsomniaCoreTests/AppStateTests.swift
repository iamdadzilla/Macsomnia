import XCTest
@testable import MacsomniaCore

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

    func testObserveExternalDetectionTurnsOnAndAlertsOnce() {
        var alerts = 0
        state.onExternalDetected = { alerts += 1 }
        state.observe(systemDisabled: true)   // external turns it on
        XCTAssertTrue(state.isOn)
        XCTAssertFalse(state.initiatedByApp)
        XCTAssertNil(state.expiry)
        state.observe(systemDisabled: true)   // still external, no repeat alert
        XCTAssertEqual(alerts, 1)
    }

    func testObserveTrueWhileAppInitiatedIsNoOp() throws {
        try state.enable(.indefinite)
        var alerts = 0
        state.onExternalDetected = { alerts += 1 }
        state.observe(systemDisabled: true)
        XCTAssertTrue(state.isOn)
        XCTAssertTrue(state.initiatedByApp)
        XCTAssertEqual(alerts, 0)
    }

    func testObserveFalseWhileOnReconcilesOff() throws {
        try state.enable(.indefinite)
        var reconciled = 0
        state.onReconciledOff = { reconciled += 1 }
        state.observe(systemDisabled: false)
        XCTAssertFalse(state.isOn)
        XCTAssertNil(state.expiry)
        XCTAssertEqual(reconciled, 1)
    }

    func testObserveFalseWhileOffIsNoOp() {
        var reconciled = 0
        state.onReconciledOff = { reconciled += 1 }
        state.observe(systemDisabled: false)
        XCTAssertFalse(state.isOn)
        XCTAssertEqual(reconciled, 0)
    }

    func testExternalThenOffThenExternalAlertsTwice() {
        var alerts = 0
        state.onExternalDetected = { alerts += 1 }
        state.observe(systemDisabled: true)   // external on -> alert 1
        state.observe(systemDisabled: false)  // off
        state.observe(systemDisabled: true)   // external on again -> alert 2
        XCTAssertEqual(alerts, 2)
    }

    func testAutoOffExpiredDisablesAndNotifies() throws {
        try state.enable(.twoHours)
        var autoOffs = 0
        state.onAutoOff = { autoOffs += 1 }
        state.autoOffExpired()
        XCTAssertFalse(state.isOn)
        XCTAssertNil(state.expiry)
        XCTAssertEqual(mock.disableCount, 1)
        XCTAssertEqual(autoOffs, 1)
    }

    func testMenuTextOffIsNil() {
        XCTAssertNil(state.menuText(now: fixedNow))
    }

    func testMenuTextExternal() {
        state.observe(systemDisabled: true)
        XCTAssertEqual(state.menuText(now: fixedNow), "Awake (ext)")
    }

    func testMenuTextIndefinite() throws {
        try state.enable(.indefinite)
        XCTAssertEqual(state.menuText(now: fixedNow), "Awake ∞")
    }

    func testMenuTextTimedShowsCountdown() throws {
        try state.enable(.fourHours)
        let later = fixedNow.addingTimeInterval(3600)   // 3h left
        XCTAssertEqual(state.menuText(now: later), "Awake 3:00")
    }

    func testStatusTextVariants() throws {
        XCTAssertEqual(state.statusText(now: fixedNow), "OFF")
        try state.enable(.indefinite)
        XCTAssertEqual(state.statusText(now: fixedNow), "ON — until turned off")
    }

    func testStatusTextExternalAndTimed() throws {
        state.observe(systemDisabled: true)
        XCTAssertEqual(state.statusText(now: fixedNow), "ON — set outside this app")

        state.observe(systemDisabled: false)   // reset to OFF
        try state.enable(.fourHours)
        let later = fixedNow.addingTimeInterval(3600)   // 3h left
        XCTAssertEqual(state.statusText(now: later), "ON — 3:00 remaining")
    }
}
