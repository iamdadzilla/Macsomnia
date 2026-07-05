import SwiftUI
import KeepAwakeCore

struct MenuLabel: View {
    @ObservedObject var state: AppState
    /// Refresh tick source so the countdown updates; value itself is unused.
    let tick: Date

    var body: some View {
        if let text = state.menuText(now: tick) {
            // ON: red "crossed-out zzz" (sleep disabled) plus the countdown.
            HStack(spacing: 3) {
                SlashedZzz()
                Text(text)
            }
        } else {
            // OFF: plain zzz — sleep is allowed.
            Image(systemName: "zzz")
        }
    }
}

/// A "zzz" symbol with a diagonal slash through it, tinted red: the active
/// (sleep-disabled) menu-bar indicator. The slash keeps it distinct from the
/// OFF `zzz` even where the menu bar renders it monochrome.
struct SlashedZzz: View {
    var body: some View {
        Image(systemName: "zzz")
            .overlay(
                GeometryReader { geo in
                    Path { path in
                        // Prohibition-style slash: top-left to bottom-right.
                        path.move(to: CGPoint(x: geo.size.width * 0.08, y: geo.size.height * 0.08))
                        path.addLine(to: CGPoint(x: geo.size.width * 0.92, y: geo.size.height * 0.92))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                }
            )
            .foregroundStyle(.red)
    }
}

struct MenuContent: View {
    @ObservedObject var state: AppState
    let tick: Date
    let onEnable: (KeepAwakeDuration) -> Void
    let onDisable: () -> Void

    var body: some View {
        Text(state.statusText(now: tick))

        Divider()

        if state.isOn {
            Button("Disable now", action: onDisable)
        } else {
            ForEach(KeepAwakeDuration.allCases, id: \.self) { duration in
                Button(duration.menuLabel) { onEnable(duration) }
            }
        }

        Divider()

        Button("Quit KeepAwake") { NSApplication.shared.terminate(nil) }
    }
}
