import SwiftUI
import KeepAwakeCore

struct MenuLabel: View {
    @ObservedObject var state: AppState
    /// Refresh tick source so the countdown updates; value itself is unused.
    let tick: Date

    var body: some View {
        if let text = state.menuText(now: tick) {
            Label(text, systemImage: "cup.and.saucer.fill")
        } else {
            Image(systemName: "moon.zzz")
        }
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
