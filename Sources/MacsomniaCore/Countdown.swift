import Foundation

public enum Countdown {
    /// Formats a remaining interval as `H:MM`, rounding minutes up.
    /// Negative or zero input renders as `0:00`.
    public static func format(remaining: TimeInterval) -> String {
        guard remaining > 0 else { return "0:00" }
        let totalMinutes = Int((remaining / 60).rounded(.up))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
}
