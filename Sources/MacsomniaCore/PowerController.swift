import Foundation

public protocol PowerControlling {
    func enable() throws           // sleep 0 ; disablesleep 1
    func disable() throws          // sleep 5 ; disablesleep 0
    func readSleepDisabled() throws -> Bool
    /// True when `pmset` can be run as root without a password (the sudoers rule
    /// is installed). Used to decide whether to trigger first-run provisioning.
    func hasPasswordlessAccess() -> Bool
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

    public func hasPasswordlessAccess() -> Bool {
        // Grep the user's sudo rules for an actual NOPASSWD pmset grant. This
        // reflects the installed rule regardless of sudo's credential-cache
        // state — a plain `sudo -n pmset` would also succeed on a cached
        // timestamp (e.g. the user ran sudo recently), giving a false positive
        // and skipping first-run provisioning.
        guard let listing = try? capture("/usr/bin/sudo", ["-n", "-l"]) else { return false }
        return listing.range(of: "NOPASSWD:[^\n]*pmset", options: .regularExpression) != nil
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
}
