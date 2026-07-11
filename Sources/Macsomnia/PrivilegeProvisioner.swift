import AppKit

/// Installs the password-free `pmset` sudoers rule for the current user via a
/// single native macOS admin-authorization dialog. This is the first-run path
/// so a downloaded / Homebrew-installed app works without the user opening a
/// terminal.
enum PrivilegeProvisioner {
    enum ProvisionError: Error, CustomStringConvertible {
        case invalidUserName
        case cancelled
        case failed(String)

        var description: String {
            switch self {
            case .invalidUserName: return "Unexpected user name; cannot install the permission rule."
            case .cancelled:       return "Authorization was cancelled."
            case .failed(let m):   return "Could not install the permission rule: \(m)"
            }
        }
    }

    /// Presents the admin prompt and installs `/etc/sudoers.d/macsomnia`.
    /// Throws `.cancelled` if the user dismisses the auth dialog.
    static func installSudoersRule() throws {
        let user = NSUserName()
        // Defensive: macOS short names are [A-Za-z0-9._-]; refuse anything else
        // rather than bake it into a privileged shell command.
        let allowed = CharacterSet(charactersIn:
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
        guard !user.isEmpty, user.unicodeScalars.allSatisfy(allowed.contains) else {
            throw ProvisionError.invalidUserName
        }

        // The entire installer runs as root INSIDE the `do shell script` literal
        // — nothing is written to disk first, so there is no user-writable file
        // for root to execute (no TOCTOU). The rule is written to a root-owned
        // temp file, syntax-checked with visudo, then atomically installed with
        // correct ownership/permissions. The validated user name is the only
        // interpolation, inside a single-quoted printf argument.
        let shell = "t=\"$(/usr/bin/mktemp)\"; "
            + "printf '%s ALL=(root) NOPASSWD: /usr/bin/pmset\\n' '\(user)' > \"$t\"; "
            + "if /usr/sbin/visudo -cf \"$t\" >/dev/null 2>&1; then "
            + "/usr/bin/install -m 0440 -o root -g wheel \"$t\" /etc/sudoers.d/macsomnia; "
            + "/bin/rm -f \"$t\"; else /bin/rm -f \"$t\"; exit 2; fi"

        // Escape the command for the AppleScript string literal (backslash first).
        let escaped = shell
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let source = "do shell script \"\(escaped)\" with administrator privileges"

        guard let script = NSAppleScript(source: source) else {
            throw ProvisionError.failed("could not build authorization script")
        }
        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let code = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
            if code == -128 { throw ProvisionError.cancelled }   // user cancelled
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "unknown error"
            throw ProvisionError.failed(message)
        }
    }
}
