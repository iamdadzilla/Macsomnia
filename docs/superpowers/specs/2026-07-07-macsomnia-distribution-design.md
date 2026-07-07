# Macsomnia — Distribution Design Spec

**Date:** 2026-07-07
**Status:** Planned (execute after Apple Developer enrollment)

## Purpose

Get Macsomnia from "builds locally on my machine" to "anyone can install it,"
via two channels: **GitHub** (source + prebuilt releases) and **Homebrew**
(`brew install --cask`). This spec captures the work, the decisions, and the
ordering. It does not cover the app's behavior (see the KeepAwake design spec) —
only packaging, signing, and delivery.

## Current state (done)

- Renamed to **Macsomnia**; bundle id `net.jperry.Macsomnia`; MIT `LICENSE`.
- Source builds via `make-app.sh` into an **unsigned** `Macsomnia.app`.
- `install-sudoers.sh` grants password-free `pmset` for the *current* user (a
  hand-run, hardcoded-username step — fine locally, a problem for distribution;
  see "Sudoers for distribution").
- Repo published to `github.com/iamdadzilla/Macsomnia` (source channel, phase 1).

## The gating fact

An app someone **downloads** is quarantined by Gatekeeper. Unless it is signed
with a **Developer ID** certificate and **notarized** by Apple, users get
"unidentified developer" / "damaged" and cannot open it normally. Therefore:

- **Source channel** (clone + build yourself) needs **no signing** — a locally
  built app is trusted.
- **Any prebuilt-binary channel** (GitHub Releases, Homebrew cask) needs
  **signing + notarization**, which needs a paid **Apple Developer Program**
  membership ($99/yr). This is the prerequisite for everything below phase 1.

## Decisions

1. **Name:** Macsomnia. (Done.)
2. **License:** MIT. (Done.)
3. **App Store:** No. Disabling clamshell sleep circumvents a thermal-protective
   behavior and requires root — sandbox-incompatible and likely rejected.
4. **Homebrew tap:** Ship first via a **personal tap**
   (`github.com/iamdadzilla/homebrew-macsomnia`); defer official `homebrew/cask`
   until there's demand (it has a notability bar + notarization expectation).
5. **Sudoers for distribution — OPEN DECISION** (see below). Pick before phase 4.

## Sudoers for distribution (open decision)

`install-sudoers.sh` hardcodes the username and must be run by hand. Two ways to
make a distributed app self-provision:

- **Option A — first-run admin prompt (cheap).** On first enable, if
  `sudo -n pmset` fails, the app installs the sudoers rule for the current user
  via an admin-authenticated helper (AppleScript `do shell script … with
  administrator privileges`, or `SMJobBless`-style one-shot). One code change;
  keeps the current architecture. Downside: "an app that writes a sudoers rule"
  is a legitimate trust smell.
- **Option B — `SMAppService` privileged helper (clean).** Drop sudoers
  entirely; a signed helper daemon runs `pmset` as root, app ↔ helper over XPC.
  The notarization-friendly, distribution-shaped design. Downside: XPC + helper
  signing ceremony; larger change.

**Recommendation:** Option A for the first notarized release (fast), migrate to
Option B when/if the project gets real users. Both are compatible with a cask.

## Phased plan

### Phase 1 — Source on GitHub (no cost) — DONE
- MIT `LICENSE`, `README` with build + hardware warning.
- `gh repo create iamdadzilla/Macsomnia --public --source . --push`.
- Users: `git clone`, `./make-app.sh`, `./install-sudoers.sh`. No signing.
- Optional cleanup: the `docs/superpowers/` design docs use the original working
  name "KeepAwake" and reference the internal workflow. Decide whether to keep,
  rename, or drop them from the public repo.

### Phase 2 — Apple Developer enrollment (prerequisite for 3+)
- Enroll in the Apple Developer Program ($99/yr).
- Create a **Developer ID Application** certificate; install it in the login
  keychain. Record the Team ID.
- Create an app-specific password (or an App Store Connect API key) for
  `notarytool`.

### Phase 3 — Sign + notarize the app
- Add a hardened-runtime signing step (new `sign-app.sh` or extend `make-app.sh`):
  ```
  codesign --force --options runtime --timestamp \
    --sign "Developer ID Application: Jim Perry (TEAMID)" Macsomnia.app
  ```
  - Hardened runtime + spawning `sudo`/`pmset` via `Process` is allowed; no extra
    entitlement is required for that. If a helper is added (Option B), it must be
    signed too and share the Team ID.
- Zip and notarize:
  ```
  ditto -c -k --keepParent Macsomnia.app Macsomnia.zip
  xcrun notarytool submit Macsomnia.zip --keychain-profile "macsomnia-notary" --wait
  xcrun stapler staple Macsomnia.app
  ```
- Verify: `spctl -a -vvv -t exec Macsomnia.app` → "accepted, source=Notarized
  Developer ID".

### Phase 4 — GitHub Releases pipeline
- Package a stapled artifact (`.zip` is simplest; `.dmg` is nicer UX — decide).
- **GitHub Actions** on tag push (`v*`): build release, sign, notarize, staple,
  package, create the Release, upload the artifact. Store the Developer ID cert
  (base64 `.p12`) and notary credentials as encrypted repo secrets; import the
  cert into a temporary keychain in the workflow.
- Output: `Macsomnia-<version>.zip` (or `.dmg`) attached to each GitHub Release,
  downloadable and openable without Gatekeeper friction.

### Phase 5 — Homebrew cask (personal tap)
- Repo `github.com/iamdadzilla/homebrew-macsomnia`, file
  `Casks/macsomnia.rb`:
  ```ruby
  cask "macsomnia" do
    version "1.0.0"
    sha256 "<sha of the release zip>"
    url "https://github.com/iamdadzilla/Macsomnia/releases/download/v#{version}/Macsomnia-#{version}.zip"
    name "Macsomnia"
    desc "Keeps your Mac awake with the lid closed"
    homepage "https://github.com/iamdadzilla/Macsomnia"
    depends_on macos: ">= :ventura"
    app "Macsomnia.app"
    caveats <<~EOS
      Macsomnia needs password-free pmset. If prompted on first use, allow it,
      or run the bundled install-sudoers.sh. It defeats a thermal safeguard —
      see the first-run warning.
    EOS
  end
  ```
- Install: `brew install --cask iamdadzilla/macsomnia/macsomnia`.
- The cask requires the notarized Release artifact from phase 4 (URL + SHA256).
- Automate cask version/sha bumps from the release workflow (optional).

### Phase 6 — Later / optional
- Migrate sudoers → `SMAppService` helper (Option B) for a frictionless install.
- Submit to official `homebrew/cask` once there's demand (notability +
  notarization already satisfied).

## Open decisions to resolve before executing

1. Repo visibility for phase 1 (public vs staged private). *(User to create.)*
2. Sudoers approach for distribution: **A** (first-run prompt) now vs **B**
   (`SMAppService`) — recommendation is A first.
3. Release artifact format: `.zip` (simple) vs `.dmg` (nicer).
4. Whether to publish/rename/drop `docs/superpowers/` in the public repo.

## Deliverables (when executed)

- `sign-app.sh` (or extended `make-app.sh`) — sign + notarize + staple.
- `.github/workflows/release.yml` — tagged release pipeline.
- `homebrew-macsomnia` tap repo with `Casks/macsomnia.rb`.
- First-run sudoers provisioning (Option A) or `SMAppService` helper (Option B).
