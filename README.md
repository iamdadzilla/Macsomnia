# Macsomnia

A macOS menu-bar app that stops your Mac from sleeping — including
clamshell (lid closed) with no external display — for keeping long-running
jobs (AI agents, builds, downloads) alive.

## ⚠️ Hardware warning

Disabling clamshell sleep defeats a thermal-protective behavior. It is intended
for **light** workloads. Running heavy, sustained CPU/GPU load with the lid
closed and no external cooling can overheat the machine. Use the auto-off timer.

## Setup

1. Build the app: `./make-app.sh`, then move `Macsomnia.app` to `/Applications`.
2. Open Macsomnia. On first launch it shows a one-time danger/liability warning
   you must accept. A `zzz` icon then appears in the menu bar.
3. The first time you enable it, Macsomnia registers a small privileged helper
   (an `SMAppService` daemon) that runs `pmset` as root. macOS may ask you to
   allow Macsomnia's background item in **System Settings → General → Login
   Items & Extensions** (under "Allow in the Background"). Approve it, then
   enable again — after that it works without any further prompts.

## Use

- Click the icon → choose a duration (30 min / 2 h / 4 h / 8 h / until off).
- While ON: a red strip appears across the top of every screen, the label shows
  a live countdown, and an auto-off timer will disable it.
- **Disable now** turns it off; quitting the app also restores normal sleep.
- If sleep gets disabled by anything else, Macsomnia detects it within ~5s,
  shows the red strip, and notifies you.

## What it runs

The privileged helper daemon runs these as root (reached over XPC):

- Enable: `pmset -b sleep 0 ; pmset -b disablesleep 1`
- Disable: `pmset -b sleep 5 ; pmset -b disablesleep 0`
