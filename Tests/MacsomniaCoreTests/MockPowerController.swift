import Foundation
@testable import MacsomniaCore

final class MockPowerController: PowerControlling {
    private(set) var enableCount = 0
    private(set) var disableCount = 0
    var enableError: Error?
    var sleepDisabledToReturn = false
    var readError: Error?
    var passwordlessAccess = true

    func enable() throws {
        if let enableError { throw enableError }
        enableCount += 1
    }

    func disable() throws {
        disableCount += 1
    }

    func readSleepDisabled() throws -> Bool {
        if let readError { throw readError }
        return sleepDisabledToReturn
    }

    func hasPasswordlessAccess() -> Bool { passwordlessAccess }
}
