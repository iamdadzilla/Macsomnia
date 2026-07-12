import Foundation

public protocol PowerControlling {
    func enable() throws           // sleep 0 ; disablesleep 1
    func disable() throws          // sleep 5 ; disablesleep 0
    func readSleepDisabled() throws -> Bool
}

public struct PmsetError: Error, CustomStringConvertible {
    public let code: Int32
    public let message: String
    public init(code: Int32, message: String) {
        self.code = code
        self.message = message
    }
    public var description: String { "pmset failed (\(code)): \(message)" }
}
