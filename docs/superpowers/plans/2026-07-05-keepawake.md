# KeepAwake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A macOS menu-bar app that disables system sleep (including clamshell/lid-closed with no external display) with one click, makes the ON state unmissable (full-width red strip + text label + auto-off timer), and mirrors the real system state by polling `pmset`.

**Architecture:** A Swift Package with two targets. `KeepAwakeCore` holds all pure logic (pmset parsing, durations, countdown formatting, the `AppState` state machine, the `StateMonitor` poller) behind a `PowerControlling` protocol — this is TDD'd with `swift test` against a mock. `KeepAwake` is a thin SwiftUI/AppKit app shell (`MenuBarExtra`, red-strip `NSWindow` overlay, timers, quit handler) that wires the core to the system and is verified manually. Root pmset calls are made password-free via a one-time `/etc/sudoers.d` rule.

**Tech Stack:** Swift 5.9+, SwiftUI `MenuBarExtra` (macOS 13+), AppKit (`NSWindow` overlay, `UserNotifications`), Swift Package Manager, XCTest.

---

## File Structure

```
KeepAwake/
  Package.swift
  Sources/
    KeepAwakeCore/
      PowerController.swift      # PowerControlling protocol + RealPowerController
      SleepStateParser.swift     # parse `pmset -g` -> Bool?
      KeepAwakeDuration.swift    # duration enum: interval + menu label
      Countdown.swift            # TimeInterval -> "H:MM"
      StateMonitor.swift         # polling coordinator (timer + read closure)
      AppState.swift             # ObservableObject state machine + reconciliation
    KeepAwake/
      KeepAwakeApp.swift         # @main App + MenuBarExtra scene
      MenuViews.swift            # MenuLabel + MenuContent SwiftUI views
      RedStripOverlay.swift      # AppKit red strip NSWindow manager
      AppDelegate.swift          # activation policy, timers, notifications, quit handler
  Tests/
    KeepAwakeCoreTests/
      MockPowerController.swift
      SleepStateParserTests.swift
      KeepAwakeDurationTests.swift
      CountdownTests.swift
      AppStateTests.swift
      StateMonitorTests.swift
  install-sudoers.sh
  make-app.sh
  README.md
```

**Testability seams:** `AppState` takes a `PowerControlling` and an injectable clock (`now: () -> Date`); all system side effects (real pmset, timers, NSWindow, notifications) live in the app shell. Tests never touch the real system.

---

### Task 1: Package scaffold

**Files:**
- Create: `Package.swift`
- Create: `Sources/KeepAwakeCore/SleepStateParser.swift` (placeholder)
- Create: `Tests/KeepAwakeCoreTests/ScaffoldTests.swift`

- [ ] **Step 1: Create `Package.swift`**

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KeepAwake",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "KeepAwakeCore"),
        .executableTarget(
            name: "KeepAwake",
            dependencies: ["KeepAwakeCore"]
        ),
        .testTarget(
            name: "KeepAwakeCoreTests",
            dependencies: ["KeepAwakeCore"]
        ),
    ]
)
```

- [ ] **Step 2: Create a placeholder source so the target compiles**

`Sources/KeepAwakeCore/SleepStateParser.swift`:

```swift
import Foundation

public enum SleepStateParser {}
```

- [ ] **Step 3: Create a scaffold test**

`Tests/KeepAwakeCoreTests/ScaffoldTests.swift`:

```swift
import XCTest
@testable import KeepAwakeCore

final class ScaffoldTests: XCTestCase {
    func testHarnessRuns() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 4: Create an empty entry point so the executable target links**

`Sources/KeepAwake/KeepAwakeApp.swift`:

```swift
// Replaced with the real App in Task 12.
print("KeepAwake placeholder")
```

- [ ] **Step 5: Run the build and tests**

Run: `cd /Users/jim/Repos/KeepAwake && swift test`
Expected: build succeeds, `testHarnessRuns` PASSES.

- [ ] **Step 6: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "chore: scaffold KeepAwake swift package"
```

---

### Task 2: SleepStateParser

Parses `pmset -g` output to find the `SleepDisabled` flag. Returns `nil` when absent (so the poller can retry rather than assume a value).

**Files:**
- Modify: `Sources/KeepAwakeCore/SleepStateParser.swift`
- Test: `Tests/KeepAwakeCoreTests/SleepStateParserTests.swift`

- [ ] **Step 1: Write the failing tests**

`Tests/KeepAwakeCoreTests/SleepStateParserTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter SleepStateParserTests`
Expected: FAIL — `sleepDisabled(fromPmsetOutput:)` does not exist.

- [ ] **Step 3: Implement the parser**

Replace the contents of `Sources/KeepAwakeCore/SleepStateParser.swift`:

```swift
import Foundation

public enum SleepStateParser {
    /// Returns the value of the `SleepDisabled` flag from `pmset -g` output,
    /// or `nil` if the flag is not present.
    public static func sleepDisabled(fromPmsetOutput output: String) -> Bool? {
        for line in output.split(whereSeparator: \.isNewline) {
            let fields = line.split(whereSeparator: \.isWhitespace)
            guard fields.count >= 2, fields[0] == "SleepDisabled" else { continue }
            return fields[1] == "1"
        }
        return nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter SleepStateParserTests`
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/KeepAwakeCore/SleepStateParser.swift Tests/KeepAwakeCoreTests/SleepStateParserTests.swift
git commit -m "feat: parse SleepDisabled from pmset output"
```

---

### Task 3: KeepAwakeDuration

The set of timeout choices offered in the menu, each with a time interval (nil = indefinite) and a display label.

**Files:**
- Create: `Sources/KeepAwakeCore/KeepAwakeDuration.swift`
- Test: `Tests/KeepAwakeCoreTests/KeepAwakeDurationTests.swift`

- [ ] **Step 1: Write the failing tests**

`Tests/KeepAwakeCoreTests/KeepAwakeDurationTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter KeepAwakeDurationTests`
Expected: FAIL — `KeepAwakeDuration` does not exist.

- [ ] **Step 3: Implement the enum**

`Sources/KeepAwakeCore/KeepAwakeDuration.swift`:

```swift
import Foundation

public enum KeepAwakeDuration: CaseIterable, Equatable {
    case thirtyMinutes
    case twoHours
    case fourHours
    case eightHours
    case indefinite

    /// Seconds until auto-off, or `nil` for no auto-off.
    public var timeInterval: TimeInterval? {
        switch self {
        case .thirtyMinutes: return 30 * 60
        case .twoHours:      return 2 * 3600
        case .fourHours:     return 4 * 3600
        case .eightHours:    return 8 * 3600
        case .indefinite:    return nil
        }
    }

    public var menuLabel: String {
        switch self {
        case .thirtyMinutes: return "30 minutes"
        case .twoHours:      return "2 hours"
        case .fourHours:     return "4 hours"
        case .eightHours:    return "8 hours"
        case .indefinite:    return "Until I turn it off"
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter KeepAwakeDurationTests`
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/KeepAwakeCore/KeepAwakeDuration.swift Tests/KeepAwakeCoreTests/KeepAwakeDurationTests.swift
git commit -m "feat: add KeepAwakeDuration menu options"
```

---

### Task 4: Countdown formatting

Formats a remaining `TimeInterval` as `H:MM`, rounding up to whole minutes and clamping negatives to `0:00`.

**Files:**
- Create: `Sources/KeepAwakeCore/Countdown.swift`
- Test: `Tests/KeepAwakeCoreTests/CountdownTests.swift`

- [ ] **Step 1: Write the failing tests**

`Tests/KeepAwakeCoreTests/CountdownTests.swift`:

```swift
import XCTest
@testable import KeepAwakeCore

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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter CountdownTests`
Expected: FAIL — `Countdown` does not exist.

- [ ] **Step 3: Implement the formatter**

`Sources/KeepAwakeCore/Countdown.swift`:

```swift
import Foundation

public enum Countdown {
    /// Formats a remaining interval as `H:MM`, rounding minutes up.
    /// Negative or zero input renders as `0:00`.
    public static func format(remaining: TimeInterval) -> String {
        guard remaining > 0 else { return "0:00" }
        let totalMinutes = Int((remaining / 60).rounded(.up))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter CountdownTests`
Expected: 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/KeepAwakeCore/Countdown.swift Tests/KeepAwakeCoreTests/CountdownTests.swift
git commit -m "feat: format countdown as H:MM"
```

---

### Task 5: PowerControlling protocol + mock + real implementation

Defines the seam between logic and the system. The mock backs all `AppState`/`StateMonitor` tests. The real implementation shells out to `pmset` (reads without sudo, writes with sudo) and is verified manually later.

**Files:**
- Create: `Sources/KeepAwakeCore/PowerController.swift`
- Create: `Tests/KeepAwakeCoreTests/MockPowerController.swift`

- [ ] **Step 1: Define the protocol and real implementation**

`Sources/KeepAwakeCore/PowerController.swift`:

```swift
import Foundation

public protocol PowerControlling {
    func enable() throws           // sleep 0 ; disablesleep 1
    func disable() throws          // sleep 5 ; disablesleep 0
    func readSleepDisabled() throws -> Bool
}

public struct PmsetError: Error, CustomStringConvertible {
    public let code: Int32
    public let message: String
    public var description: String { "pmset failed (\(code)): \(message)" }
}

/// Runs the real `pmset` binary. Writes require root (via the sudoers rule
/// installed by install-sudoers.sh); reads do not.
public final class RealPowerController: PowerControlling {
    public init() {}

    public func enable() throws {
        try runSudo(["-b", "sleep", "0"])
        try runSudo(["-b", "disablesleep", "1"])
    }

    public func disable() throws {
        try runSudo(["-b", "sleep", "5"])
        try runSudo(["-b", "disablesleep", "0"])
    }

    public func readSleepDisabled() throws -> Bool {
        let output = try capture("/usr/bin/pmset", ["-g"])
        guard let value = SleepStateParser.sleepDisabled(fromPmsetOutput: output) else {
            throw PmsetError(code: -1, message: "SleepDisabled not found in pmset -g")
        }
        return value
    }

    // MARK: - Process helpers

    private func runSudo(_ pmsetArgs: [String]) throws {
        _ = try capture("/usr/bin/sudo", ["-n", "/usr/bin/pmset"] + pmsetArgs)
    }

    @discardableResult
    private func capture(_ launchPath: String, _ args: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        process.waitUntilExit()
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            let message = String(data: errData, encoding: .utf8) ?? "unknown error"
            throw PmsetError(code: process.terminationStatus, message: message)
        }
        return String(data: outData, encoding: .utf8) ?? ""
    }
}
```

Note: `sudo -n` fails fast (non-interactive) if the sudoers rule is missing, surfacing a `PmsetError` instead of hanging.

- [ ] **Step 2: Create the mock for tests**

`Tests/KeepAwakeCoreTests/MockPowerController.swift`:

```swift
import Foundation
@testable import KeepAwakeCore

final class MockPowerController: PowerControlling {
    private(set) var enableCount = 0
    private(set) var disableCount = 0
    var enableError: Error?
    var sleepDisabledToReturn = false
    var readError: Error?

    func enable() throws {
        if let enableError { throw enableError }
        enableCount += 1
    }

    func disable() throws {
        disableCount += 1
    }

    func readSleepDisabled() throws -> Bool {
        if let readError { throw readError }
        return sleepDisabledToReturn
    }
}
```

- [ ] **Step 3: Verify everything still builds**

Run: `swift build`
Expected: builds with no errors.

- [ ] **Step 4: Commit**

```bash
git add Sources/KeepAwakeCore/PowerController.swift Tests/KeepAwakeCoreTests/MockPowerController.swift
git commit -m "feat: add PowerControlling protocol, real pmset impl, and mock"
```

---

### Task 6: AppState — enable, disable, and failure handling

The state machine core. `enable(_:)` calls the power controller, flips state, and records the expiry (arming auto-off via a callback). A failed `enable()` must NOT flip state — the UI needs the truth.

**Files:**
- Create: `Sources/KeepAwakeCore/AppState.swift`
- Test: `Tests/KeepAwakeCoreTests/AppStateTests.swift`

- [ ] **Step 1: Write the failing tests**

`Tests/KeepAwakeCoreTests/AppStateTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter AppStateTests`
Expected: FAIL — `AppState` does not exist.

- [ ] **Step 3: Implement AppState (enable/disable portion)**

`Sources/KeepAwakeCore/AppState.swift`:

```swift
import Foundation
import Combine

public final class AppState: ObservableObject {
    @Published public private(set) var isOn: Bool = false {
        didSet { if isOn != oldValue { onIsOnChanged(isOn) } }
    }
    @Published public private(set) var initiatedByApp: Bool = false
    @Published public private(set) var expiry: Date?

    private let power: PowerControlling
    private let now: () -> Date

    /// Called with the new expiry (or nil) so the app shell can (re)schedule
    /// or cancel the auto-off timer.
    public var onArmAutoOff: (Date?) -> Void = { _ in }
    /// Called when `isOn` flips, so the app shell can show/hide the red strip.
    public var onIsOnChanged: (Bool) -> Void = { _ in }
    /// Called once when sleep is detected as disabled by something outside this app.
    public var onExternalDetected: () -> Void = {}
    /// Called when the auto-off timer elapses.
    public var onAutoOff: () -> Void = {}
    /// Called when a poll shows the system is no longer sleep-disabled while we thought it was.
    public var onReconciledOff: () -> Void = {}

    public init(power: PowerControlling, now: @escaping () -> Date = { Date() }) {
        self.power = power
        self.now = now
    }

    public func enable(_ duration: KeepAwakeDuration) throws {
        try power.enable()
        initiatedByApp = true
        setExpiry(duration.timeInterval.map { now().addingTimeInterval($0) })
        isOn = true
    }

    public func disableByUser() throws {
        try power.disable()
        resetOff()
    }

    // MARK: - Private

    private func setExpiry(_ date: Date?) {
        expiry = date
        onArmAutoOff(date)
    }

    private func resetOff() {
        initiatedByApp = false
        setExpiry(nil)
        isOn = false
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter AppStateTests`
Expected: 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/KeepAwakeCore/AppState.swift Tests/KeepAwakeCoreTests/AppStateTests.swift
git commit -m "feat: AppState enable/disable state machine"
```

---

### Task 7: AppState — poll reconciliation (`observe`)

Implements the spec's reconciliation table: the real system state wins. Detecting an external keep-awake fires the alert exactly once; the system turning off while we thought it was on reconciles to OFF.

**Files:**
- Modify: `Sources/KeepAwakeCore/AppState.swift`
- Modify: `Tests/KeepAwakeCoreTests/AppStateTests.swift`

- [ ] **Step 1: Add the failing reconciliation tests**

Append these methods inside `AppStateTests`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter AppStateTests`
Expected: FAIL — `observe(systemDisabled:)` does not exist.

- [ ] **Step 3: Implement `observe`**

Add this method to `AppState` (inside the class, after `disableByUser`):

```swift
    /// Reconciles UI state to the real system state observed by polling.
    /// The system value is authoritative.
    public func observe(systemDisabled: Bool) {
        if systemDisabled {
            guard !isOn else { return }   // already on (by us or previously-detected external)
            initiatedByApp = false
            setExpiry(nil)
            isOn = true
            onExternalDetected()
        } else {
            guard isOn else { return }
            resetOff()
            onReconciledOff()
        }
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter AppStateTests`
Expected: all AppState tests PASS (11 total).

- [ ] **Step 5: Commit**

```bash
git add Sources/KeepAwakeCore/AppState.swift Tests/KeepAwakeCoreTests/AppStateTests.swift
git commit -m "feat: AppState poll reconciliation with external detection"
```

---

### Task 8: AppState — auto-off expiry and menu text

`autoOffExpired()` behaves like a disable but fires the auto-off callback. `menuText(now:)` produces the always-visible label text (nil when OFF, so the view shows the moon icon).

**Files:**
- Modify: `Sources/KeepAwakeCore/AppState.swift`
- Modify: `Tests/KeepAwakeCoreTests/AppStateTests.swift`

- [ ] **Step 1: Add the failing tests**

Append inside `AppStateTests`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter AppStateTests`
Expected: FAIL — `autoOffExpired`, `menuText`, `statusText` do not exist.

- [ ] **Step 3: Implement the methods**

Add to `AppState` (inside the class):

```swift
    public func autoOffExpired() {
        try? power.disable()
        resetOff()
        onAutoOff()
    }

    /// Compact text for the menu-bar label. `nil` means "OFF" (show icon only).
    public func menuText(now: Date) -> String? {
        guard isOn else { return nil }
        if !initiatedByApp { return "Awake (ext)" }
        guard let expiry else { return "Awake ∞" }
        return "Awake " + Countdown.format(remaining: expiry.timeIntervalSince(now))
    }

    /// Full status line shown inside the menu.
    public func statusText(now: Date) -> String {
        guard isOn else { return "OFF" }
        if !initiatedByApp { return "ON — set outside this app" }
        guard let expiry else { return "ON — until turned off" }
        return "ON — " + Countdown.format(remaining: expiry.timeIntervalSince(now)) + " remaining"
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter AppStateTests`
Expected: all AppState tests PASS (17 total).

- [ ] **Step 5: Commit**

```bash
git add Sources/KeepAwakeCore/AppState.swift Tests/KeepAwakeCoreTests/AppStateTests.swift
git commit -m "feat: AppState auto-off and menu/status text"
```

---

### Task 9: StateMonitor

A thin polling coordinator: it reads system state through an injected closure and forwards the result. The timer scheduling is exercised manually; `poll()` is unit-tested.

**Files:**
- Create: `Sources/KeepAwakeCore/StateMonitor.swift`
- Test: `Tests/KeepAwakeCoreTests/StateMonitorTests.swift`

- [ ] **Step 1: Write the failing tests**

`Tests/KeepAwakeCoreTests/StateMonitorTests.swift`:

```swift
import XCTest
@testable import KeepAwakeCore

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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter StateMonitorTests`
Expected: FAIL — `StateMonitor` does not exist.

- [ ] **Step 3: Implement StateMonitor**

`Sources/KeepAwakeCore/StateMonitor.swift`:

```swift
import Foundation

/// Polls system sleep state and forwards each reading. `read` returns the
/// observed `SleepDisabled` value, or `nil` when it could not be determined
/// (in which case the reading is skipped and retried next tick).
public final class StateMonitor {
    private let read: () -> Bool?
    private let onObserved: (Bool) -> Void
    private var timer: Timer?

    public init(read: @escaping () -> Bool?, onObserved: @escaping (Bool) -> Void) {
        self.read = read
        self.onObserved = onObserved
    }

    public func poll() {
        if let value = read() {
            onObserved(value)
        }
    }

    public func start(interval: TimeInterval) {
        stop()
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter StateMonitorTests`
Expected: 2 tests PASS.

- [ ] **Step 5: Run the full suite**

Run: `swift test`
Expected: all tests PASS (Task 1–9 suites).

- [ ] **Step 6: Commit**

```bash
git add Sources/KeepAwakeCore/StateMonitor.swift Tests/KeepAwakeCoreTests/StateMonitorTests.swift
git commit -m "feat: add StateMonitor polling coordinator"
```

---

### Task 10: RedStripOverlay (AppKit)

The full-width red strip. Manual verification only (no XCTest for AppKit windows).

**Files:**
- Create: `Sources/KeepAwake/RedStripOverlay.swift`

- [ ] **Step 1: Implement the overlay manager**

`Sources/KeepAwake/RedStripOverlay.swift`:

```swift
import AppKit

/// Manages a thin, mouse-transparent red strip pinned to the top edge of every
/// screen. Visible across Spaces and over fullscreen apps.
final class RedStripOverlay {
    private var windows: [NSWindow] = []
    private(set) var isShown = false
    private let stripHeight: CGFloat = 6

    func show() {
        isShown = true
        build()
    }

    func hide() {
        isShown = false
        teardown()
    }

    /// Rebuild for the current screen arrangement (call on display changes).
    func refresh() {
        if isShown { build() }
    }

    private func build() {
        teardown()
        for screen in NSScreen.screens {
            let frame = NSRect(
                x: screen.frame.minX,
                y: screen.frame.maxY - stripHeight,
                width: screen.frame.width,
                height: stripHeight
            )
            let window = NSWindow(
                contentRect: frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .systemRed
            window.level = .screenSaver           // above the menu bar
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    private func teardown() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}
```

- [ ] **Step 2: Verify it builds**

Run: `swift build`
Expected: builds with no errors. (Visual verification happens in Task 14.)

- [ ] **Step 3: Commit**

```bash
git add Sources/KeepAwake/RedStripOverlay.swift
git commit -m "feat: add red strip overlay window manager"
```

---

### Task 11: Menu views (SwiftUI)

The `MenuBarExtra` label and menu content. `MenuLabel` shows the coffee icon + text when ON, moon icon when OFF. `MenuContent` shows the status line, the duration choices (when OFF) or Disable (when ON), and Quit.

**Files:**
- Create: `Sources/KeepAwake/MenuViews.swift`

- [ ] **Step 1: Implement the views**

`Sources/KeepAwake/MenuViews.swift`:

```swift
import SwiftUI
import KeepAwakeCore

struct MenuLabel: View {
    @ObservedObject var state: AppState
    /// Refresh tick source so the countdown updates; value itself is unused.
    let tick: Date

    var body: some View {
        if let text = state.menuText(now: tick) {
            Label(text, systemImage: "cup.and.saucer.fill")
        } else {
            Image(systemName: "moon.zzz")
        }
    }
}

struct MenuContent: View {
    @ObservedObject var state: AppState
    let tick: Date
    let onEnable: (KeepAwakeDuration) -> Void
    let onDisable: () -> Void

    var body: some View {
        Text(state.statusText(now: tick))

        Divider()

        if state.isOn {
            Button("Disable now", action: onDisable)
        } else {
            ForEach(KeepAwakeDuration.allCases, id: \.self) { duration in
                Button(duration.menuLabel) { onEnable(duration) }
            }
        }

        Divider()

        Button("Quit KeepAwake") { NSApplication.shared.terminate(nil) }
    }
}
```

- [ ] **Step 2: Verify it builds**

Run: `swift build`
Expected: builds with no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/KeepAwake/MenuViews.swift
git commit -m "feat: add menu bar label and menu content views"
```

---

### Task 12: App entry point + AppDelegate wiring

Wires the core to the system: activation policy (no Dock icon), the poll timer, the display-refresh tick, auto-off scheduling, notifications, screen-change handling, and the quit-restores-sleep safety behavior.

**Files:**
- Create: `Sources/KeepAwake/AppDelegate.swift`
- Replace: `Sources/KeepAwake/KeepAwakeApp.swift`

- [ ] **Step 1: Implement the AppDelegate**

`Sources/KeepAwake/AppDelegate.swift`:

```swift
import AppKit
import Combine
import UserNotifications
import KeepAwakeCore

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let power: PowerControlling = RealPowerController()
    lazy var appState = AppState(power: power)
    private let overlay = RedStripOverlay()
    private var monitor: StateMonitor!
    private var displayTimer: Timer?
    private var autoOffTimer: Timer?

    /// Bumped by the display timer to drive live countdown re-rendering.
    @Published var tick = Date()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
        requestNotificationAuthorization()
        wireCallbacks()
        startMonitoring()
        startDisplayTimer()
        observeScreenChanges()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Safety: never leave the Mac unable to sleep after quit.
        try? power.disable()
        overlay.hide()
    }

    // MARK: - Wiring

    private func wireCallbacks() {
        appState.onIsOnChanged = { [weak self] isOn in
            if isOn { self?.overlay.show() } else { self?.overlay.hide() }
        }
        appState.onArmAutoOff = { [weak self] expiry in
            self?.scheduleAutoOff(at: expiry)
        }
        appState.onExternalDetected = { [weak self] in
            self?.notify(title: "Keep-Awake is ON",
                         body: "Sleep was disabled outside this app.")
        }
        appState.onAutoOff = { [weak self] in
            self?.notify(title: "Keep-Awake turned off",
                         body: "The auto-off timer elapsed.")
        }
        appState.onReconciledOff = { [weak self] in
            self?.scheduleAutoOff(at: nil)
        }
    }

    private func startMonitoring() {
        monitor = StateMonitor(
            read: { [weak self] in try? self?.power.readSleepDisabled() },
            onObserved: { [weak self] disabled in self?.appState.observe(systemDisabled: disabled) }
        )
        monitor.poll()             // reconcile immediately on launch
        monitor.start(interval: 5)
    }

    private func startDisplayTimer() {
        displayTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.tick = Date()
        }
    }

    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.overlay.refresh()
        }
    }

    // MARK: - Auto-off timer

    private func scheduleAutoOff(at expiry: Date?) {
        autoOffTimer?.invalidate()
        autoOffTimer = nil
        guard let expiry else { return }
        let interval = max(0, expiry.timeIntervalSinceNow)
        autoOffTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.appState.autoOffExpired()
        }
    }

    // MARK: - User actions (from the menu)

    func enable(_ duration: KeepAwakeDuration) {
        do {
            try appState.enable(duration)
            tick = Date()
        } catch {
            presentFailure(error)
        }
    }

    func disable() {
        do {
            try appState.disableByUser()
            tick = Date()
        } catch {
            presentFailure(error)
        }
    }

    // MARK: - Notifications & errors

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func presentFailure(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "KeepAwake couldn't change sleep settings"
        alert.informativeText = """
        \(error)

        If you haven't yet, run install-sudoers.sh to allow password-free pmset.
        """
        alert.alertStyle = .warning
        alert.runModal()
    }
}
```

- [ ] **Step 2: Replace the app entry point**

Replace the entire contents of `Sources/KeepAwake/KeepAwakeApp.swift`:

```swift
import SwiftUI
import KeepAwakeCore

@main
struct KeepAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(
                state: delegate.appState,
                tick: delegate.tick,
                onEnable: { delegate.enable($0) },
                onDisable: { delegate.disable() }
            )
        } label: {
            MenuLabel(state: delegate.appState, tick: delegate.tick)
        }
        .menuBarExtraStyle(.menu)
    }
}
```

- [ ] **Step 3: Verify it builds**

Run: `swift build`
Expected: builds with no errors.

- [ ] **Step 4: Commit**

```bash
git add Sources/KeepAwake/AppDelegate.swift Sources/KeepAwake/KeepAwakeApp.swift
git commit -m "feat: wire app shell — timers, notifications, quit safety"
```

---

### Task 13: install-sudoers.sh

One-time setup granting password-free `pmset`.

**Files:**
- Create: `install-sudoers.sh`

- [ ] **Step 1: Write the script**

`install-sudoers.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Grants the current user password-free use of /usr/bin/pmset, so KeepAwake
# can disable/enable sleep without a password prompt. Run once.

RULE_FILE="/etc/sudoers.d/keepawake"
TMP_FILE="$(mktemp)"
USER_NAME="$(id -un)"

printf '%s ALL=(root) NOPASSWD: /usr/bin/pmset\n' "$USER_NAME" > "$TMP_FILE"

# Validate before installing — never install an unparseable sudoers file.
if ! sudo visudo -cf "$TMP_FILE" >/dev/null; then
    echo "Refusing to install: sudoers syntax check failed." >&2
    rm -f "$TMP_FILE"
    exit 1
fi

sudo install -m 0440 -o root -g wheel "$TMP_FILE" "$RULE_FILE"
rm -f "$TMP_FILE"

echo "Installed $RULE_FILE for user '$USER_NAME'."
echo "Verifying password-free pmset..."
if sudo -n /usr/bin/pmset -g >/dev/null 2>&1; then
    echo "OK — KeepAwake can now run pmset without a password."
else
    echo "WARNING: password-free pmset did not work. Check the rule." >&2
    exit 1
fi
```

- [ ] **Step 2: Make it executable and syntax-check it**

Run: `chmod +x install-sudoers.sh && bash -n install-sudoers.sh && echo OK`
Expected: prints `OK` (no syntax errors). Do not run it yet — that happens in Task 14.

- [ ] **Step 3: Commit**

```bash
git add install-sudoers.sh
git commit -m "feat: add sudoers install script for password-free pmset"
```

---

### Task 14: App bundle, README, and end-to-end verification

Package the executable as a proper `.app` (needed for `LSUIElement`, a stable bundle id for notifications, and login-item use), document it, then verify the real behavior.

**Files:**
- Create: `make-app.sh`
- Create: `README.md`

- [ ] **Step 1: Write the bundle build script**

`make-app.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Builds a release binary and wraps it in KeepAwake.app with an Info.plist
# marking it as a menu-bar (accessory) app.

APP="KeepAwake.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"

swift build -c release
rm -rf "$APP"
mkdir -p "$MACOS"
cp ".build/release/KeepAwake" "$MACOS/KeepAwake"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>KeepAwake</string>
    <key>CFBundleDisplayName</key>       <string>KeepAwake</string>
    <key>CFBundleIdentifier</key>        <string>net.jperry.KeepAwake</string>
    <key>CFBundleVersion</key>           <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>CFBundleExecutable</key>        <string>KeepAwake</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <key>LSUIElement</key>               <true/>
</dict>
</plist>
PLIST

echo "Built $APP. Move it to /Applications and open it."
```

- [ ] **Step 2: Write the README**

`README.md`:

```markdown
# KeepAwake

A macOS menu-bar app that stops your Mac from sleeping — including
clamshell (lid closed) with no external display — for keeping long-running
jobs (AI agents, builds, downloads) alive.

## ⚠️ Hardware warning

Disabling clamshell sleep defeats a thermal-protective behavior. It is intended
for **light** workloads. Running heavy, sustained CPU/GPU load with the lid
closed and no external cooling can overheat the machine. Use the auto-off timer.

## Setup

1. Build the app: `./make-app.sh`, then move `KeepAwake.app` to `/Applications`.
2. Grant password-free `pmset` (one time): `./install-sudoers.sh`.
3. Open KeepAwake. A coffee/moon icon appears in the menu bar.

## Use

- Click the icon → choose a duration (30 min / 2 h / 4 h / 8 h / until off).
- While ON: a red strip appears across the top of every screen, the label shows
  a live countdown, and an auto-off timer will disable it.
- **Disable now** turns it off; quitting the app also restores normal sleep.
- If sleep gets disabled by anything else, KeepAwake detects it within ~5s,
  shows the red strip, and notifies you.

## What it runs

- Enable: `sudo pmset -b sleep 0 ; sudo pmset -b disablesleep 1`
- Disable: `sudo pmset -b sleep 5 ; sudo pmset -b disablesleep 0`
```

- [ ] **Step 3: Build the bundle**

Run: `chmod +x make-app.sh && ./make-app.sh`
Expected: prints "Built KeepAwake.app". `ls KeepAwake.app/Contents/MacOS/KeepAwake` exists.

- [ ] **Step 4: Install the sudoers rule**

Run: `./install-sudoers.sh`
Expected: prompts for your password once, then prints "OK — KeepAwake can now run pmset without a password."

- [ ] **Step 5: Manual end-to-end verification**

Perform each check and confirm:
1. Open `KeepAwake.app`. A moon icon appears in the menu bar, no Dock icon.
2. Click it → **2 hours**. The red strip appears at the top of every display; the label shows `Awake 1:59` and counts down.
3. Run `pmset -g | grep SleepDisabled` in Terminal → shows `1`.
4. Close the lid with no external display for ~1 min → the Mac stays awake (fans/activity continue; it does not sleep).
5. In Terminal run `sudo pmset -b disablesleep 0`. Within ~5s the strip disappears and you get a "turned off" reconciliation (label returns to moon).
6. Click it → **30 minutes**, then in Terminal `sudo pmset -b disablesleep 1` is NOT needed — instead test external detection: with KeepAwake OFF, run `sudo pmset -b disablesleep 1` in Terminal → within ~5s the red strip appears, the label reads `Awake (ext)`, and you get an "is ON" notification. Turn it off via the menu's **Disable now**.
7. Enable again, then **Quit KeepAwake** → `pmset -g | grep SleepDisabled` shows `0` (quit restored sleep).

- [ ] **Step 6: Commit**

```bash
git add make-app.sh README.md
git commit -m "feat: add app bundle build, README, and hardware warning"
```

---

## Self-Review Notes

- **Spec coverage:** clamshell via `disablesleep 1` (Task 5); sudoers model (Task 13); red strip on all displays + across Spaces/fullscreen + mouse-transparent (Task 10); menu label text cue + duration menu + Disable/status (Tasks 8, 11); auto-off timer with menu-selected duration (Tasks 8, 12); StateMonitor 5s polling + reconciliation table + immediate poll on action (Tasks 7, 9, 12); auto-disable on quit + start-OFF-then-reconcile + pmset-failure alert (Task 12); screen-change strip rebuild (Tasks 10, 12); unit tests for state machine/countdown/parser/reconciliation/external-alert-once (Tasks 2–9); manual clamshell/strip/sudoers/quit checks (Task 14). All covered.
- **Type consistency:** `PowerControlling.{enable,disable,readSleepDisabled}` used identically in mock, real impl, `AppState`, and `AppDelegate`. `AppState` callbacks (`onIsOnChanged`, `onArmAutoOff`, `onExternalDetected`, `onAutoOff`, `onReconciledOff`) defined in Task 6/7 and consumed in Task 12. `menuText`/`statusText`/`observe`/`autoOffExpired` signatures match across tasks.
- **v2/publishing** is intentionally out of scope per the spec.
