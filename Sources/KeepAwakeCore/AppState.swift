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
