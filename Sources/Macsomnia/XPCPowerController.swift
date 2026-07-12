import Foundation
import MacsomniaCore

final class XPCPowerController: PowerControlling {
    func enable() throws { try setSleepDisabled(true) }
    func disable() throws { try setSleepDisabled(false) }

    func readSleepDisabled() throws -> Bool {
        let conn = makeConnection(); defer { conn.invalidate() }
        var value = false, found = false, connErr: Error?
        let sem = DispatchSemaphore(value: 0)
        let proxy = conn.remoteObjectProxyWithErrorHandler { connErr = $0; sem.signal() } as? MacsomniaHelperProtocol
        proxy?.readSleepDisabled { f, v in found = f; value = v; sem.signal() }
        sem.wait()
        if let connErr { throw connErr }
        guard found else { throw PmsetError(code: -1, message: "SleepDisabled not found") }
        return value
    }

    private func setSleepDisabled(_ disabled: Bool) throws {
        let conn = makeConnection(); defer { conn.invalidate() }
        var failure: String?, connErr: Error?
        let sem = DispatchSemaphore(value: 0)
        let proxy = conn.remoteObjectProxyWithErrorHandler { connErr = $0; sem.signal() } as? MacsomniaHelperProtocol
        proxy?.setSleepDisabled(disabled) { ok, msg in if !ok { failure = msg ?? "unknown" }; sem.signal() }
        sem.wait()
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
