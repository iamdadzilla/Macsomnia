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
