import Foundation
import MacsomniaCore

final class HelperService: NSObject, MacsomniaHelperProtocol, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection c: NSXPCConnection) -> Bool {
        // Only accept connections from our signed app (Developer ID + our bundle id + our team).
        do {
            try c.setCodeSigningRequirement(
                "anchor apple generic and identifier \"net.jperry.Macsomnia\" and certificate leaf[subject.OU] = \"9RV6LVA7L9\"")
        } catch { return false }
        c.exportedInterface = NSXPCInterface(with: MacsomniaHelperProtocol.self)
        c.exportedObject = self
        c.resume()
        return true
    }

    func setSleepDisabled(_ disabled: Bool, reply: @escaping (Bool, String?) -> Void) {
        do {
            try run(["-b", "sleep", disabled ? "0" : "5"])
            try run(["-b", "disablesleep", disabled ? "1" : "0"])
            reply(true, nil)
        } catch { reply(false, "\(error)") }
    }

    func readSleepDisabled(reply: @escaping (Bool, Bool) -> Void) {
        do {
            let out = try capture(["-g"])
            if let v = SleepStateParser.sleepDisabled(fromPmsetOutput: out) { reply(true, v) }
            else { reply(false, false) }
        } catch { reply(false, false) }
    }

    // MARK: - Process helpers

    // Run /usr/bin/pmset directly as root. Drain pipes before waitUntilExit (avoid deadlock).
    @discardableResult
    private func capture(_ args: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = args
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        // Drain both pipes to EOF before waiting, so a child that writes more
        // than the OS pipe buffer can't block and deadlock waitUntilExit().
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: errData, encoding: .utf8) ?? "unknown error"
            throw PmsetError(code: process.terminationStatus, message: message)
        }
        return String(data: outData, encoding: .utf8) ?? ""
    }

    private func run(_ args: [String]) throws { _ = try capture(args) }
}

let delegate = HelperService()
let listener = NSXPCListener(machServiceName: MacsomniaHelperInfo.machServiceName)
listener.delegate = delegate
listener.resume()
dispatchMain()
