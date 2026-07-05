import Foundation

public enum SleepStateParser {
    /// Returns the value of the `SleepDisabled` flag from `pmset -g` output,
    /// or `nil` if the flag is not present.
    public static func sleepDisabled(fromPmsetOutput output: String) -> Bool? {
        for line in output.split(whereSeparator: \.isNewline) {
            let fields = line.split(whereSeparator: \.isWhitespace)
            guard fields.count >= 2, fields[0] == "SleepDisabled" else { continue }
            return fields[1] == "1"
        }
        return nil
    }
}
