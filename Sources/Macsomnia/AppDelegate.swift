import AppKit
import Combine
import UserNotifications
import MacsomniaCore

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let power: PowerControlling = XPCPowerController()
    lazy var appState = AppState(power: power)
    private let overlay = RedStripOverlay()
    private var monitor: StateMonitor!
    private var displayTimer: Timer?
    private var autoOffTimer: Timer?
    private let warningGate = WarningGate(store: UserDefaults.standard)

    /// Ticking time source the menu views observe (see Clock). Driven by the
    /// display timer; drives the live countdown.
    let clock = Clock()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
        presentWarningIfNeeded()                // first run: accept or quit
        requestNotificationAuthorization()
        wireCallbacks()
        startMonitoring()
        startDisplayTimer()
        observeScreenChanges()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Safety: if sleep is currently disabled, restore it on quit. Guarded on
        // isOn so declining the first-run warning (nothing enabled) can't trigger
        // a spurious failure alert.
        overlay.hide()
        guard appState.isOn else { return }
        do {
            try power.disable()
        } catch {
            FileHandle.standardError.write(Data("Macsomnia: failed to restore sleep on quit: \(error)\n".utf8))
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("error.restore.title", bundle: .module, comment: "")
            alert.informativeText = String(
                format: NSLocalizedString("error.restore.body", bundle: .module, comment: ""),
                "\(error)"
            )
            alert.alertStyle = .critical
            alert.runModal()
        }
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
            self?.notify(title: NSLocalizedString("notification.enabled.title", bundle: .module, comment: ""),
                         body: NSLocalizedString("notification.enabled.body", bundle: .module, comment: ""))
        }
        appState.onAutoOff = { [weak self] in
            self?.notify(title: NSLocalizedString("notification.disabled.title", bundle: .module, comment: ""),
                         body: NSLocalizedString("notification.disabled.body", bundle: .module, comment: ""))
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
        // Register in .common mode (not just .default) so it also fires during
        // menu tracking; scheduledTimer is default-only.
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            self?.clock.now = Date()
        }
        RunLoop.main.add(timer, forMode: .common)
        displayTimer = timer
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
        // .common mode too: the safety auto-off must still fire while the app is
        // an idle menu-bar agent (same starvation as the display timer).
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            self?.appState.autoOffExpired()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoOffTimer = timer
    }

    // MARK: - User actions (from the menu)

    func enable(_ duration: MacsomniaDuration) {
        if !HelperManager.isEnabled, !ensureHelper() { return }
        do {
            try appState.enable(duration)
            clock.now = Date()
        } catch {
            presentFailure(error)
        }
    }

    /// First-run: register the privileged helper daemon via SMAppService. macOS
    /// may require the user to approve Macsomnia's background item in System
    /// Settings → Login Items before it becomes active. Returns true only once
    /// the helper is enabled and ready to serve XPC requests.
    private func ensureHelper() -> Bool {
        switch HelperManager.status {
        case .enabled:
            return true
        case .requiresApproval:
            presentApprovalNeeded()
            return false
        default:
            do {
                try HelperManager.register()
            } catch {
                presentFailure(error)
                return false
            }
            if HelperManager.isEnabled { return true }
            presentApprovalNeeded()
            return false
        }
    }

    /// Directs the user to approve Macsomnia's background item so the helper can run.
    private func presentApprovalNeeded() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("approval.title", bundle: .module, comment: "")
        alert.informativeText = NSLocalizedString("approval.body", bundle: .module, comment: "")
        alert.addButton(withTitle: NSLocalizedString("button.openSettings", bundle: .module, comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.cancel", bundle: .module, comment: ""))
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            HelperManager.openLoginItemsSettings()
        }
    }

    func disable() {
        do {
            try appState.disableByUser()
            clock.now = Date()
        } catch {
            presentFailure(error)
        }
    }

    // MARK: - First-run warning

    private func presentWarningIfNeeded() {
        guard !warningGate.hasAccepted else { return }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("warning.title", bundle: .module, comment: "")
        alert.informativeText = NSLocalizedString("warning.body", bundle: .module, comment: "")
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("button.accept", bundle: .module, comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.quit", bundle: .module, comment: ""))
        NSApp.activate(ignoringOtherApps: true)   // accessory app: bring modal to front
        if alert.runModal() == .alertFirstButtonReturn {
            warningGate.accept()
        } else {
            NSApp.terminate(nil)
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
        alert.messageText = NSLocalizedString("error.changeSettings.title", bundle: .module, comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("error.changeSettings.body", bundle: .module, comment: ""),
            "\(error)"
        )
        alert.alertStyle = .warning
        alert.runModal()
    }
}

extension UserDefaults: FlagStore {
    public func flag(_ key: String) -> Bool { bool(forKey: key) }
    public func setFlag(_ key: String, _ value: Bool) { set(value, forKey: key) }
}
