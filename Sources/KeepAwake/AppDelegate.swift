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
        overlay.hide()
        do {
            try power.disable()
        } catch {
            FileHandle.standardError.write(Data("KeepAwake: failed to restore sleep on quit: \(error)\n".utf8))
            let alert = NSAlert()
            alert.messageText = "KeepAwake could not restore normal sleep"
            alert.informativeText = """
            Your Mac may remain unable to sleep. Run this in Terminal to fix it:

            sudo pmset -b disablesleep 0; sudo pmset -b sleep 5

            (\(error))
            """
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
