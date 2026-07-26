import Foundation
import Combine

/// A ticking time source the menu views observe directly. Passing time as a
/// plain value through the `App`/`Scene` body does NOT refresh a `MenuBarExtra`
/// label — the Scene body isn't re-evaluated when an `@Published` on the app
/// delegate changes. Observing this object at the view level (`@ObservedObject`)
/// does re-render the label on every tick.
final class Clock: ObservableObject {
    @Published var now = Date()
}
