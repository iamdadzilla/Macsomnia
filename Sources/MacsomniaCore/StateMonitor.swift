import Foundation

/// Polls system sleep state and forwards each reading. `read` returns the
/// observed `SleepDisabled` value, or `nil` when it could not be determined
/// (in which case the reading is skipped and retried next tick).
public final class StateMonitor {
    private let read: () -> Bool?
    private let onObserved: (Bool) -> Void
    private var timer: Timer?
    private let workQueue = DispatchQueue(label: "com.macsomnia.statemonitor")
    private var inFlight = false   // touched only on the main thread

    public init(read: @escaping () -> Bool?, onObserved: @escaping (Bool) -> Void) {
        self.read = read
        self.onObserved = onObserved
    }

    /// Call on the main thread. `read()` may block (synchronous XPC to the
    /// privileged helper), so it runs on a background queue and never stalls the
    /// caller's run loop — otherwise a slow/unreachable helper at launch would
    /// keep SwiftUI from ever installing the menu-bar item. `onObserved` is
    /// delivered back on the main thread. Overlapping ticks are coalesced.
    public func poll() {
        if inFlight { return }
        inFlight = true
        workQueue.async { [weak self] in
            let value = self?.read()
            DispatchQueue.main.async {
                self?.inFlight = false
                if let value { self?.onObserved(value) }
            }
        }
    }

    /// Must be called on the main thread: the timer is scheduled on the main run loop.
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
