import Foundation

public enum MacsomniaDuration: CaseIterable, Equatable {
    case thirtyMinutes
    case twoHours
    case fourHours
    case eightHours
    case indefinite

    /// Seconds until auto-off, or `nil` for no auto-off.
    public var timeInterval: TimeInterval? {
        switch self {
        case .thirtyMinutes: return 30 * 60
        case .twoHours:      return 2 * 3600
        case .fourHours:     return 4 * 3600
        case .eightHours:    return 8 * 3600
        case .indefinite:    return nil
        }
    }

    public var menuLabel: String {
        let bundle = Bundle.module
        switch self {
        case .thirtyMinutes: return NSLocalizedString("duration.30min", bundle: bundle, comment: "")
        case .twoHours:      return NSLocalizedString("duration.2h", bundle: bundle, comment: "")
        case .fourHours:     return NSLocalizedString("duration.4h", bundle: bundle, comment: "")
        case .eightHours:    return NSLocalizedString("duration.8h", bundle: bundle, comment: "")
        case .indefinite:    return NSLocalizedString("duration.indefinite", bundle: bundle, comment: "")
        }
    }
}
