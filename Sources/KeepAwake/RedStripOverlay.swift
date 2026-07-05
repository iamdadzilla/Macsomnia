import AppKit

/// Manages a thin, mouse-transparent red strip pinned to the top edge of every
/// screen. Visible across Spaces and over fullscreen apps.
final class RedStripOverlay {
    private var windows: [NSWindow] = []
    private(set) var isShown = false
    private let stripHeight: CGFloat = 6

    func show() {
        isShown = true
        build()
    }

    func hide() {
        isShown = false
        teardown()
    }

    /// Rebuild for the current screen arrangement (call on display changes).
    func refresh() {
        if isShown { build() }
    }

    private func build() {
        teardown()
        for screen in NSScreen.screens {
            let frame = NSRect(
                x: screen.frame.minX,
                y: screen.frame.maxY - stripHeight,
                width: screen.frame.width,
                height: stripHeight
            )
            let window = NSWindow(
                contentRect: frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .systemRed
            window.level = .screenSaver           // above the menu bar
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    private func teardown() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}
