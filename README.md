# Macsomnia

A macOS menu-bar app that stops your Mac from sleeping — including **clamshell
(lid closed) with no external display** — to keep long-running light jobs (AI
agents, builds, downloads) alive.

When active, a red strip spans the top of every screen and the menu-bar label
shows a live countdown, so you can never miss that it's on. An auto-off timer
turns it off after a duration you pick.

Requires macOS 13 (Ventura) or later.

## ⚠️ Hardware warning

Disabling clamshell sleep defeats a thermal-protective behavior. Macsomnia is
intended for **light** workloads. Running heavy, sustained CPU/GPU load with the
lid closed and no external cooling can cause dangerous heat buildup and may
damage your hardware. Use the auto-off timer. Macsomnia is provided as-is, with
no warranty; you use it at your own risk.

## Install

### Homebrew (recommended)

```sh
brew tap iamdadzilla/macsomnia
brew install --cask macsomnia
```

Recent Homebrew asks you to trust a third-party cask tap the first time. If the
install stops with an "untrusted tap" message, run the command it suggests
(`brew trust iamdadzilla/macsomnia`) and re-run the install.

Upgrade later with `brew upgrade --cask macsomnia`.

### Direct download

Grab the `Macsomnia-<version>.zip` from the [latest release](https://github.com/iamdadzilla/Macsomnia/releases/latest),
unzip it, and move `Macsomnia.app` to `/Applications`. Builds are signed and
notarized, so they open without Gatekeeper warnings.

### Build from source

```sh
git clone https://github.com/iamdadzilla/Macsomnia.git
cd Macsomnia
./make-app.sh          # builds Macsomnia.app
```

Then move `Macsomnia.app` to `/Applications`. (Requires the Xcode command-line
tools.)

## First run

1. Open Macsomnia. It shows a one-time danger/liability warning you must accept.
   A `zzz` icon then appears in the menu bar.
2. The first time you enable it, Macsomnia registers a small privileged helper
   (an `SMAppService` background daemon) that runs `pmset` as root. macOS asks
   you to allow Macsomnia's background item in **System Settings → General →
   Login Items & Extensions** (under "Allow in the Background"). Approve it, then
   enable again — after that it works with no further prompts.

## Use

- Click the icon → choose a duration: **30 min · 2 h · 4 h · 8 h · until I turn
  it off**.
- While ON: a red strip appears across the top of every display, the label shows
  a live countdown, and the auto-off timer will disable it.
- **Disable now** turns it off. Quitting the app also restores normal sleep.
- If sleep gets disabled by anything else, Macsomnia detects it within ~5s,
  shows the red strip, and notifies you.

## How it works

A signed helper daemon runs these as root, reached over XPC — only Macsomnia's
own signed app is allowed to talk to it:

- Enable: `pmset -b sleep 0 ; pmset -b disablesleep 1`
- Disable: `pmset -b sleep 5 ; pmset -b disablesleep 0`

`disablesleep 1` is what keeps the Mac awake with the lid closed — stronger than
the idle-sleep prevention that `caffeinate` and similar tools use.

## Uninstall

```sh
brew uninstall --cask macsomnia          # or delete Macsomnia.app
```

Upgrading from 1.0 (which used a sudoers rule instead of the helper)? Remove the
now-unused rule:

```sh
sudo rm -f /etc/sudoers.d/macsomnia
```

## License

MIT — see [LICENSE](LICENSE).

## See also

- [Promotion plan](PROMOTION-PLAN.md) — launch and outreach notes
