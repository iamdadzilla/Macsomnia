# KeepAwake — Design Spec

**Date:** 2026-07-05
**Status:** Approved for planning

## Purpose

A macOS menu bar app that lets the user disable system sleep — including
**clamshell (lid-closed) sleep with no external display** — with a single
click, and makes the active state impossible to accidentally leave on.

When enabled it issues:

```
sudo pmset -b sleep 0
sudo pmset -b disablesleep 1
```

When disabled it issues:

```
sudo pmset -b sleep 5
sudo pmset -b disablesleep 0
```

`disablesleep 1` is the key setting: unlike IOKit power assertions (what
`caffeinate` / typical keep-awake apps use), it keeps the Mac awake even with
the lid closed and no external monitor attached. It requires root, which drives
the sudoers approach below.

## Non-goals (YAGNI)

- No distribution to other users (personal machine). No notarization/App Store.
- No per-argument sudoers lockdown (broad `pmset` grant is acceptable here).
- No persistence of the ON state across launches — the app always starts OFF
  and reconciles to reality (see StateMonitor).
- No IOKit-assertion fallback — clamshell behavior specifically requires pmset.

## Stack

- Native SwiftUI `MenuBarExtra` app, macOS 13+ (Ventura), built in Xcode.
- `LSUIElement = true` (Info.plist) → menu bar only, no Dock icon.
- No third-party dependencies.

## Privilege model

`pmset` requires root. To run it without a password prompt (there is no TTY in
a GUI app), a one-time setup installs a sudoers rule.

**`install-sudoers.sh`** writes `/etc/sudoers.d/keepawake`:

```
jim ALL=(root) NOPASSWD: /usr/bin/pmset
```

- File owned by root, mode `0440`.
- Validated with `visudo -c` before install; abort if invalid.
- Script is run once manually by the user (it will prompt for password that one
  time, via normal sudo).

Trade-off (accepted): this grants passwordless `pmset` generally, not only the
exact argument sets used here. Simplest and appropriate for a personal machine.

## Components

Each component has one purpose, a small interface, and is testable in isolation.

### 1. `PowerController` (protocol + real impl)

The only thing that touches the system power settings.

```
protocol PowerControlling {
    func enable() throws        // sleep 0 ; disablesleep 1
    func disable() throws       // sleep 5 ; disablesleep 0
    func readSleepDisabled() throws -> Bool   // parse `pmset -g`
}
```

- Real impl runs `/usr/bin/sudo /usr/bin/pmset …` via `Process`, checks exit
  codes, throws on non-zero.
- `readSleepDisabled()` runs `pmset -g` and parses the `SleepDisabled` value.
- A mock impl backs unit tests for the state machine.

### 2. `StateMonitor`

Polls the **real** system state and treats it as the single source of truth.

- Runs `PowerControlling.readSleepDisabled()` every ~5 seconds.
- Also polled immediately after any app-initiated enable/disable (no waiting for
  the next tick).
- Publishes the observed `sleepDisabled` boolean to `AppState`.

Reconciliation rules (system state wins):

| System `SleepDisabled` | App believed | Action |
|---|---|---|
| true | ON (app set it) | Normal ON. |
| true | OFF (external) | Treat as ON: show strip, menu reads `ON — set outside this app`, offer Disable now, fire one-time alert. |
| false | ON | Reconcile to OFF: drop strip, notify "Keep-Awake turned off". Cancel any auto-off timer. |
| false | OFF | Normal OFF. |

### 3. `AppState` (ObservableObject)

Holds and drives UI truth:

- `isEnabled` (derived from StateMonitor's observed state)
- `initiatedByApp` (did we set it, or is it external?)
- `selectedDuration`, `expiry: Date?`
- Owns the auto-off `Timer`.

Coordinates: on user "enable for N", calls `PowerController.enable()`, arms
timer, triggers immediate poll. On "disable", calls `disable()`, cancels timer,
triggers immediate poll.

### 4. `RedStripOverlay`

Unmissable passive visual cue.

- Borderless `NSWindow`, `ignoresMouseEvents = true` (clicks pass through to the
  menu bar and apps below).
- Thin bright-red strip (~5–6 px) pinned to the very top edge of the screen.
- Window level above the menu bar; `collectionBehavior` includes
  `.canJoinAllSpaces` and `.fullScreenAuxiliary` → visible across Spaces and
  over fullscreen apps.
- Shown on **all** connected displays while ON; hidden while OFF.
- Visibility is driven by StateMonitor's observed state (mirrors reality,
  whoever set it), not merely app intent.

### 5. Menu bar UI (`MenuBarExtra`)

**Label** (always-visible text cue):

- OFF: moon/`zzz` icon only.
- ON: `☕︎ Awake H:MM` with a live countdown when a timeout is armed, or
  `☕︎ Awake ∞` for "until I turn it off", or `☕︎ Awake (external)` when set
  outside the app.

**Menu contents:**

- Status line: `Keep-Awake: ON — 3:59 remaining` / `ON — until turned off` /
  `ON — set outside this app` / `OFF`.
- **When OFF** — duration choices that each enable with that timeout:
  `30 minutes · 2 hours · 4 hours · 8 hours · Until I turn it off`.
- **When ON** — `Disable now`.
- Divider.
- `Quit`.

### 6. Auto-off timer

- Enabling with a finite duration arms a `Timer` for that interval.
- On fire: `PowerController.disable()`, drop strip, notify
  "Keep-Awake turned off".
- "Until I turn it off" arms no timer.
- Timer is cancelled on manual disable, on external-off reconciliation, and on
  quit.

## Safety behaviors

- **Auto-disable on quit:** `applicationWillTerminate` restores normal sleep
  (`disablesleep 0`, `sleep 5`) and removes the strip — quitting can never
  strand the Mac awake.
- **Start OFF on launch**, then let StateMonitor's first poll reconcile to the
  real system state (covers a keepawake left on by anything, including a prior
  crash or an external tool).
- **Failure handling:** any non-zero pmset exit (e.g. sudoers not yet installed)
  surfaces an alert pointing at `install-sudoers.sh`; the UI reflects the real
  polled state rather than a false ON.

## Data flow

```
User clicks duration ──▶ AppState.enable(duration)
                             │
                             ├─▶ PowerController.enable()  (sudo pmset …)
                             ├─▶ arm auto-off Timer
                             └─▶ trigger immediate poll
                                        │
StateMonitor (every ~5s) ──────────────┴─▶ readSleepDisabled()
                                             │
                                             ▼
                                      AppState.observed = true/false
                                             │
                        ┌────────────────────┼────────────────────┐
                        ▼                    ▼                    ▼
                 RedStripOverlay        MenuBarExtra          alerts /
                 (show/hide)            (label + status)      notifications
```

## Error handling summary

- pmset non-zero → alert + point to install script; do not fake success.
- `pmset -g` parse failure → log, keep last known state, retry next tick.
- Multiple displays connecting/disconnecting → strip windows rebuilt to match
  current screens on each show and on `NSApplication.didChangeScreenParameters`.

## Testing

- **Unit (mock `PowerController`):** enable/disable transitions; auto-off timer
  arms/fires/cancels; countdown formatting; StateMonitor reconciliation table
  (all four rows); external-detection alert fires once, not repeatedly.
- **Manual:** actual clamshell test (lid closed, no external display, stays
  awake); red strip visible across Spaces/fullscreen and on all displays;
  sudoers install path; quit-restores-sleep; external `sudo pmset disablesleep 1`
  from Terminal is detected and reflected.

## Deliverables

- Xcode project for the SwiftUI app.
- `install-sudoers.sh` setup script.
- README: build, sudoers setup, usage.

## Future: publishing (v2 — out of scope for this build)

Captured so it isn't lost; not implemented in v1. Build and validate the
personal/sudoers version first, then consider a distribution pass:

- **Name:** avoid "Redbull" (trademark risk). Candidate: "Redline" (on-theme
  with the red strip / running hardware hard). Alternatives: NoDoze, Lidless,
  Vigil, Wideawake.
- **GitHub:** MIT license, README with a prominent thermal/hardware warning
  (clamshell + no external display defeats a thermal-protective behavior; fine
  for light AI jobs, risky under sustained load), GitHub Actions to build + zip
  the `.app` and attach to Releases.
- **Homebrew:** ship first via a personal tap (`brew install --cask
  jperry/<tap>/<name>`); official `homebrew/cask` later (notability bar +
  notarization). Requires a Developer ID account ($99/yr) for
  signing/notarization to avoid Gatekeeper friction.
- **Privilege model for distribution:** replace the hardcoded sudoers file with
  a `SMAppService` privileged helper + XPC (no sudoers), which is the
  notarization-friendly, distribution-shaped design.
- **App Store:** not viable — disabling clamshell sleep circumvents a
  thermal-protective behavior and needs root (sandbox-incompatible).
