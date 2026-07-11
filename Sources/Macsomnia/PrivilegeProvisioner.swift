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
        // rather than bake it into a privileged shell script.
        let allowed = CharacterSet(charactersIn:
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
        guard !user.isEmpty, user.unicodeScalars.allSatisfy(allowed.contains) else {
            throw ProvisionError.invalidUserName
        }

        // Static installer; the (validated) user name is the only interpolation.
        let installer = """
        #!/bin/bash
        set -e
        tmp="$(mktemp)"
        printf '%s ALL=(root) NOPASSWD: /usr/bin/pmset\\n' '\(user)' > "$tmp"
        if /usr/sbin/visudo -cf "$tmp" >/dev/null 2>&1; then
          /usr/bin/install -m 0440 -o root -g wheel "$tmp" /etc/sudoers.d/macsomnia
          rm -f "$tmp"
        else
          rm -f "$tmp"
          exit 2
        fi
        """

        let scriptURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("macsomnia-install-\(UUID().uuidString).sh")
        try installer.write(to: scriptURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        // `quoted form of` shell-quotes the path; escape it for the AppleScript
        // string literal too.
        let asPath = scriptURL.path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let source = "do shell script \"/bin/bash \" & quoted form of \"\(asPath)\" "
            + "with administrator privileges"

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
