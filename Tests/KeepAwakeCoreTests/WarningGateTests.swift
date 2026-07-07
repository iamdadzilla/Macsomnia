import XCTest
@testable import KeepAwakeCore

private final class MemoryStore: FlagStore {
    private var values: [String: Bool] = [:]
    func flag(_ key: String) -> Bool { values[key] ?? false }
    func setFlag(_ key: String, _ value: Bool) { values[key] = value }
}

final class WarningGateTests: XCTestCase {
    func testStartsUnaccepted() {
        let gate = WarningGate(store: MemoryStore())
        XCTAssertFalse(gate.hasAccepted)
    }

    func testAcceptPersists() {
        let store = MemoryStore()
        WarningGate(store: store).accept()
        XCTAssertTrue(WarningGate(store: store).hasAccepted)
    }
}
