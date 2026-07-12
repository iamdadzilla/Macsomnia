import Foundation

@objc public protocol MacsomniaHelperProtocol {
    /// Set disablesleep (and the -b sleep timer). reply: (ok, errorMessage?)
    func setSleepDisabled(_ disabled: Bool, reply: @escaping (Bool, String?) -> Void)
    /// Read SleepDisabled. reply: (found, value)
    func readSleepDisabled(reply: @escaping (Bool, Bool) -> Void)
}

public enum MacsomniaHelperInfo {
    public static let machServiceName = "net.jperry.Macsomnia.helper"
    public static let daemonPlistName = "net.jperry.Macsomnia.helper.plist"
}
