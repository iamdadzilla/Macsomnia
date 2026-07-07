import Foundation

/// Minimal persistent boolean store, so the warning gate can be tested with an
/// in-memory double instead of `UserDefaults`.
public protocol FlagStore: AnyObject {
    func flag(_ key: String) -> Bool
    func setFlag(_ key: String, _ value: Bool)
}

/// Tracks whether the user has accepted the first-run danger warning.
public struct WarningGate {
    static let acceptedKey = "net.jperry.Macsomnia.hasAcceptedWarning"

    private let store: FlagStore

    public init(store: FlagStore) {
        self.store = store
    }

    /// True once the user has accepted the warning; the modal shows only while false.
    public var hasAccepted: Bool {
        store.flag(Self.acceptedKey)
    }

    public func accept() {
        store.setFlag(Self.acceptedKey, true)
    }
}
