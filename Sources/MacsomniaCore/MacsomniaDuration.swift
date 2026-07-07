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
        switch self {
        case .thirtyMinutes: return "30 minutes"
        case .twoHours:      return "2 hours"
        case .fourHours:     return "4 hours"
        case .eightHours:    return "8 hours"
        case .indefinite:    return "Until I turn it off"
        }
    }
}
