# Launch posts (copy-paste)

Use these as-is or tweak the first sentence. Do **not** post the same body to
every channel on the same day. GIF lives at
https://github.com/iamdadzilla/Macsomnia/blob/main/macsomnia_demo.gif

Install line everywhere:

```
brew tap iamdadzilla/macsomnia
brew install --cask macsomnia
```

---

## Show HN

**When:** Tuesday–Thursday, 8–10 AM US Eastern  
**Submit:** https://github.com/iamdadzilla/Macsomnia as **Show HN** (not a link-only post)

**Title:**

```
Show HN: Macsomnia – close your MacBook lid while keeping long jobs alive
```

Backup title:

```
Show HN: Menu-bar app to keep Mac awake in clamshell mode (open source)
```

**First comment (post immediately after submitting):**

```
I'm the author. I got tired of carrying my laptop around open during long agent
runs and builds. Most "keep awake" tools use caffeinate, which doesn't work with
the lid closed — you need pmset disablesleep. Macsomnia wraps that in a menu-bar
app with a timer, a red strip across every screen, and auto-off.

MIT licensed, signed + notarized, install via:

  brew tap iamdadzilla/macsomnia
  brew install --cask macsomnia

Happy to answer questions about the SMAppService helper or the thermal tradeoffs.
Light workloads only — closing the lid defeats a cooling path.
```

### Comment FAQ

**Why not caffeinate?**  
Doesn't prevent clamshell sleep. Close the lid with no display and the Mac still sleeps. Macsomnia uses `pmset -b disablesleep 1` via a signed privileged helper.

**Why not Amphetamine / KeepingYouAwake?**  
Those are great. Amphetamine is full-featured and closed; KeepingYouAwake is a caffeinate-style idle-sleep preventer. Macsomnia is a small MIT app aimed specifically at lid-closed jobs, with a timer and a red strip so you can't forget it's on.

**Is it safe?**  
Light workloads only. Lid closed defeats a thermal safeguard. Use the auto-off timer; read the first-run warning. I built it for agents/builds/downloads, not rendering or training.

**Why a background item / helper?**  
`pmset disablesleep` needs root. A signed SMAppService helper talks over XPC; only the Macsomnia app is allowed to call it. One-time approval in System Settings → Login Items.

---

## r/macapps

**Title:**

```
I built a menu-bar app so I could close my lid during long agent runs
```

**Body:**

```
I kept walking around the house with my MacBook open because a build or an AI
agent was still running. Closing the lid put it to sleep. caffeinate doesn't
help — that's idle sleep, not clamshell sleep.

Macsomnia is a tiny menu-bar app that calls `pmset disablesleep` through a
signed helper, with a countdown and a red strip across every screen so you
don't forget it's on. Auto-off after 30m / 2h / 4h / 8h, or until you turn it
off. Quitting restores normal sleep.

brew tap iamdadzilla/macsomnia
brew install --cask macsomnia

Repo: https://github.com/iamdadzilla/Macsomnia
MIT, signed + notarized. Light workloads only — lid closed + heavy CPU/GPU is
a heat risk. Use the timer.

Happy to take feedback.
```

Post this **1–2 days after Show HN**, and only if HN wasn't a disaster. Attach the GIF.

---

## r/MacOS (optional, later)

**Title:**

```
Open-source menu-bar app to keep a MacBook awake with the lid closed
```

**Body:**

```
If you've ever left the lid open so a download or long job wouldn't die:
Macsomnia lets you close it.

It's not caffeinate — that only blocks idle sleep. This uses `pmset -b
disablesleep 1` via a notarized helper (one-time "Allow in the Background"
prompt). Red strip + countdown while it's on; auto-off timer; restores sleep
on quit.

brew tap iamdadzilla/macsomnia && brew install --cask macsomnia
https://github.com/iamdadzilla/Macsomnia

Fair warning: this defeats a thermal safeguard. Meant for light jobs, not
sustained GPU/CPU with the lid shut.
```

---

## r/LocalLLaMA or agent communities (pick one, later)

**Title:**

```
I open-sourced a tiny Mac app so local agents can keep running with the lid closed
```

**Body:**

```
Local agents and llama.cpp jobs don't love clamshell sleep. I was carrying an
open laptop from room to room so the run wouldn't die.

Macsomnia: menu-bar toggle, timer, red strip, `pmset disablesleep` (the thing
caffeinate doesn't do). MIT, Homebrew.

brew tap iamdadzilla/macsomnia
brew install --cask macsomnia
https://github.com/iamdadzilla/Macsomnia

Not for heavy GPU loads with the lid closed — heat. Light long jobs only.
```

---

## Social (one post: X, Mastodon, or Bluesky)

```
I got tired of walking around with my laptop open during long builds and agent
runs, so I open-sourced a tiny menu-bar app that keeps the Mac awake with the
lid closed. Timer + red strip so you don't forget.

brew tap iamdadzilla/macsomnia
brew install --cask macsomnia
https://github.com/iamdadzilla/Macsomnia
```

Attach the GIF. No thread, no mass tagging.

---

## Short reply (when someone asks "how do I close the lid and keep the job alive?")

```
Macsomnia — menu-bar app that keeps your Mac awake with the lid closed.
Timer, red strip, auto-off. MIT.

brew tap iamdadzilla/macsomnia && brew install --cask macsomnia
https://github.com/iamdadzilla/Macsomnia
```

Only use this in threads where it's actually the question. Don't drop it unsolicited.
