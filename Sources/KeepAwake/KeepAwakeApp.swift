import SwiftUI
import KeepAwakeCore

@main
struct KeepAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(
                state: delegate.appState,
                tick: delegate.tick,
                onEnable: { delegate.enable($0) },
                onDisable: { delegate.disable() }
            )
        } label: {
            MenuLabel(state: delegate.appState, tick: delegate.tick)
        }
        .menuBarExtraStyle(.menu)
    }
}
