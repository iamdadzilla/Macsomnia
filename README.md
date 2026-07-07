# KeepAwake

A macOS menu-bar app that stops your Mac from sleeping — including
clamshell (lid closed) with no external display — for keeping long-running
jobs (AI agents, builds, downloads) alive.

## ⚠️ Hardware warning

Disabling clamshell sleep defeats a thermal-protective behavior. It is intended
for **light** workloads. Running heavy, sustained CPU/GPU load with the lid
closed and no external cooling can overheat the machine. Use the auto-off timer.

## Setup

1. Build the app: `./make-app.sh`, then move `KeepAwake.app` to `/Applications`.
2. Grant password-free `pmset` (one time): `./install-sudoers.sh`.
3. Open KeepAwake. On first launch it shows a one-time danger/liability
   warning you must accept. A `zzz` icon then appears in the menu bar.

## Use

- Click the icon → choose a duration (30 min / 2 h / 4 h / 8 h / until off).
- While ON: a red strip appears across the top of every screen, the label shows
  a live countdown, and an auto-off timer will disable it.
- **Disable now** turns it off; quitting the app also restores normal sleep.
- If sleep gets disabled by anything else, KeepAwake detects it within ~5s,
  shows the red strip, and notifies you.

## What it runs

- Enable: `sudo pmset -b sleep 0 ; sudo pmset -b disablesleep 1`
- Disable: `sudo pmset -b sleep 5 ; sudo pmset -b disablesleep 0`
