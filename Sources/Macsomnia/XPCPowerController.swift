import Foundation
import MacsomniaCore

/// `PowerControlling` backed by the privileged helper daemon over XPC. The
/// protocol is synchronous, so each call bridges the async XPC reply with a
/// semaphore — bounded by a timeout so a stalled/unreachable helper throws
/// instead of hanging the calling (main) thread forever.
final class XPCPowerController: PowerControlling {
    /// Generous ceiling; a real round-trip + pmset exec is sub-millisecond.
    private static let callTimeout: DispatchTimeInterval = .seconds(10)

    func enable() throws { try setSleepDisabled(true) }
    func disable() throws { try setSleepDisabled(false) }

    func readSleepDisabled() throws -> Bool {
        let conn = makeConnection(); defer { conn.invalidate() }
        var value = false, found = false, connErr: Error?
        let sem = DispatchSemaphore(value: 0)
        guard let proxy = conn.remoteObjectProxyWithErrorHandler({ connErr = $0; sem.signal() })
            as? MacsomniaHelperProtocol else {
            throw PmsetError(code: -1, message: "helper unavailable")
        }
        proxy.readSleepDisabled { f, v in found = f; value = v; sem.signal() }
        if sem.wait(timeout: .now() + Self.callTimeout) == .timedOut {
            throw PmsetError(code: -1, message: "helper timed out")
        }
        if let connErr { throw connErr }
        guard found else { throw PmsetError(code: -1, message: "SleepDisabled not found") }
        return value
    }

    private func setSleepDisabled(_ disabled: Bool) throws {
        let conn = makeConnection(); defer { conn.invalidate() }
        var failure: String?, connErr: Error?
        let sem = DispatchSemaphore(value: 0)
        guard let proxy = conn.remoteObjectProxyWithErrorHandler({ connErr = $0; sem.signal() })
            as? MacsomniaHelperProtocol else {
            throw PmsetError(code: -1, message: "helper unavailable")
        }
        proxy.setSleepDisabled(disabled) { ok, msg in if !ok { failure = msg ?? "unknown" }; sem.signal() }
        if sem.wait(timeout: .now() + Self.callTimeout) == .timedOut {
            throw PmsetError(code: -1, message: "helper timed out")
        }
        if let connErr { throw connErr }
        if let failure { throw PmsetError(code: -1, message: failure) }
    }

    private func makeConnection() -> NSXPCConnection {
        let c = NSXPCConnection(machServiceName: MacsomniaHelperInfo.machServiceName, options: .privileged)
        c.remoteObjectInterface = NSXPCInterface(with: MacsomniaHelperProtocol.self)
        c.resume()
        return c
    }
}
