# Macsomnia Promotion Plan

A practical launch and outreach plan for an MIT-licensed macOS menu-bar utility.
Goals: give back to the community and build credible reputation as someone who ships
useful, honest tools — not revenue or growth-at-all-costs.

**Repo:** https://github.com/iamdadzilla/Macsomnia  
**Install:** `brew install --cask macsomnia` (via [iamdadzilla/homebrew-macsomnia](https://github.com/iamdadzilla/homebrew-macsomnia))

---

## Positioning

### The problem (lead with this)

People carry an open MacBook around the house because a build, download, or AI agent
is still running. Macsomnia lets you **close the lid** and walk away.

### One-liner (reuse everywhere)

> Macsomnia is a menu-bar app that keeps your Mac awake with the lid closed — with a
> timer and a red strip so you don't forget.

### What Macsomnia is NOT

- Not a replacement for `caffeinate` at your desk (use built-in settings or `caffeinate` for that)
- Not a feature-rich power-user suite (that's Amphetamine — paid, mature, different scope)
- Not safe for heavy GPU/CPU work with the lid closed (thermal risk — be upfront about this)

### Unfair advantages

1. Solves a **visual, relatable pain** (open laptop vs. closed)
2. **Homebrew install** signals legitimacy
3. **Signed + notarized** release pipeline
4. **Honest safety stance** (liability modal, auto-off timer, red strip) builds trust
5. **Open source (MIT)** — forkable, auditable, no paywall

---

## Goals & success metrics

### Primary goals

| Goal | What it looks like |
|------|-------------------|
| Give back | Real people using it daily for agents/builds/downloads |
| Street cred | "I built Macsomnia" carries weight in Mac/dev circles |
| Maintainability | Small, focused project you can support without burnout |

### Metrics that matter

| Signal | Target (first 90 days) | Why |
|--------|------------------------|-----|
| GitHub stars | 100–300 (organic) | Portfolio / discoverability |
| GitHub issues & PRs | Any engagement | Proof of adoption |
| "I use this" mentions | 5–10 unprompted | Real cred |
| Homebrew installs | Steady, not spiky | Actual usage |
| HN / Reddit comment quality | Thoughtful replies | Reputation > vanity metrics |

**Ignore:** star-exchange services, follower counts, comparison flamewars.

---

## Pre-launch checklist

Complete before any public posts. Promotion amplifies quality; it can't substitute for it.

### README (30 min)

- [ ] **Install section at the top** — Homebrew first, GitHub release second, build-from-source last
- [ ] **10–15 second GIF or screen recording** showing: enable → red strip → close lid → job still running → disable
- [ ] **"Why not caffeinate?"** — one paragraph: clamshell requires `pmset disablesleep`, not `caffeinate`
- [ ] **Safety section** — keep the hardware warning prominent
- [ ] **Screenshot** of menu bar (OFF and ON states)

### GitHub repo polish (15 min)

- [ ] Repo description: `Close your MacBook lid while keeping long jobs alive`
- [ ] Topics: `macos`, `menu-bar`, `sleep`, `clamshell`, `developer-tools`, `swift`, `open-source`
- [ ] Pin a **v1.0 release** with signed `Macsomnia-1.0.zip`
- [ ] LICENSE (MIT) visible in repo root

### Homebrew (verify)

- [ ] Cask installs cleanly on a fresh Mac (or VM): `brew install --cask macsomnia`
- [ ] Cask points to signed, notarized release asset
- [ ] `brew uninstall --cask macsomnia` works cleanly

### Launch assets (1 hour)

- [ ] GIF committed to repo (e.g. `docs/demo.gif`) and embedded in README
- [ ] Draft posts written (templates below) — customize, don't copy-paste blindly
- [ ] Calendar block for **2–3 hours** after Show HN to stay in comments

---

## Audience map

Pick two primary audiences per channel. Don't spray every platform.

| Audience | Pain | Channels |
|----------|------|----------|
| Mac developers | Know `pmset`, hate manual `sudo` | Hacker News, r/mac, r/swift, Mastodon |
| Agent / AI coders | Long-running local jobs, lid closed | r/LocalLLaMA, AI Discords, dev Twitter |
| Vibe coders / indies | "Why is my laptop open on the couch?" | Twitter/X, Bluesky, personal blog |

---

## Launch sequence

### Week 0 — Prep (no public posts yet)

1. Finish pre-launch checklist
2. Tag and push `v1.0` if not already done (`git tag v1.0 && git push origin v1.0`)
3. Confirm GitHub release + Homebrew cask are live
4. Write drafts from templates below

### Week 1 — Launch

| Day | Action | Time |
|-----|--------|------|
| Tue–Thu AM (US) | **Show HN** — post as "Show HN", not link-only | 15 min post + 2–3 hr comments |
| Same day | Personal post (Twitter/X, Mastodon, or blog) with GIF | 15 min |
| +1–2 days | r/macapps or r/MacOS (if HN went okay) | 20 min + 1 hr comments |
| +3–5 days | r/LocalLLaMA or agent community (if relevant) | 20 min |

**Do not** cross-post identical text to every subreddit the same day.

### Week 2–4 — Sustain (low effort)

- Reply to GitHub issues within 48 hours
- PR to [awesome-mac](https://github.com/jaywcjlove/awesome-mac) or similar lists (small, genuine PR)
- Mention Macsomnia only when contextually relevant in threads ("I built this for exactly that")
- Consider `homebrew/cask` PR once you have stable releases and a few dozen real users

### Ongoing — Cred maintenance

- Cut a release when you fix bugs (even patch versions)
- Keep README install instructions current
- Close or label stale issues honestly ("no plans for X, PRs welcome")
- One update post per meaningful release — not every commit

---

## Channel playbook

### 1. Show HN (highest signal for cred)

**When:** Tuesday–Thursday, 8–10 AM US Eastern  
**How:** Submit https://github.com/iamdadzilla/Macsomnia as **Show HN**  
**Title options (pick one):**

- `Show HN: Macsomnia – close your MacBook lid while keeping long jobs alive`
- `Show HN: Menu-bar app to keep Mac awake in clamshell mode (open source)`

**First comment (post immediately after submitting):**

> I'm the author. I got tired of carrying my laptop around open during long agent
> runs and builds. Most "keep awake" tools use caffeinate, which doesn't work with
> the lid closed — you need pmset disablesleep. Macsomnia wraps that in a menu-bar
> app with a timer, a red strip across every screen, and auto-off.
>
> MIT licensed, signed + notarized, install via `brew install --cask macsomnia`.
> Happy to answer questions about the SMAppService helper or the thermal tradeoffs.

**Comment FAQ prep:**

| Question | Answer |
|----------|--------|
| Why not caffeinate? | Doesn't prevent clamshell sleep. Macsomnia uses `pmset -b disablesleep 1`. |
| Why not Amphetamine? | Amphetamine is great and full-featured. Macsomnia is focused, OSS, MIT — I built it for myself and open-sourced it. |
| Is it safe? | Light workloads only. Lid closed defeats a thermal safeguard. Use the timer; read the first-run warning. |
| Why does it need a background item? | Privileged helper runs pmset as root via SMAppService + XPC. One-time approval in Login Items. |

### 2. Reddit

Post as a builder sharing a fix, not a marketer. Customize per sub.

**r/macapps** (best fit)

> **Title:** I built a menu-bar app so I could close my lid during long agent runs
>
> **Body:** Short story of the open-laptop problem → what Macsomnia does → GIF →
> `brew install --cask macsomnia` → link to repo → honest note about thermal risk
> and auto-off timer → "MIT, feedback welcome"

**r/MacOS**

Same angle, slightly more technical: mention notarized release, Login Items approval,
and that it restores sleep on quit.

**r/LocalLLaMA / agent communities**

Frame around keeping local inference or agent sessions alive with lid closed.
Don't spam every AI sub — pick one where you actually participate.

### 3. Personal social (Twitter/X, Mastodon, Bluesky)

One post. No threadstorm. No mass tagging.

> I got tired of walking around with my laptop open during long builds and agent
> runs, so I open-sourced a tiny menu-bar app that keeps the Mac awake with the
> lid closed. Timer + red strip so you don't forget.
>
> brew install --cask macsomnia
> https://github.com/iamdadzilla/Macsomnia
>
> [attach GIF]

### 4. awesome-mac and similar lists

Small PR adding one line under Utilities or Productivity:

```markdown
- [Macsomnia](https://github.com/iamdadzilla/Macsomnia) - Menu-bar app to keep your Mac awake with the lid closed (MIT, Homebrew).
```

### 5. homebrew/cask (later milestone)

After ~50+ real users and stable releases, open a PR to [homebrew/homebrew-cask](https://github.com/Homebrew/homebrew-cask).
This is a credibility milestone, not a day-one requirement. Your tap works fine for launch.

---

## Post templates

### Short (social, replies)

```
Macsomnia — menu-bar app that keeps your Mac awake with the lid closed.
Timer, red strip, auto-off. MIT, brew install --cask macsomnia.
https://github.com/iamdadzilla/Macsomnia
```

### Medium (Reddit, blog)

```
## The problem

Long build / download / agent run → you carry an open MacBook around so it doesn't sleep.

## What Macsomnia does

- Click the zzz icon → pick a duration (30m to 8h)
- Red strip on every screen so you know it's on
- Auto-off when the timer ends; restores normal sleep on quit
- Detects if something else disabled sleep and alerts you

## Install

brew install --cask macsomnia

Or download the signed release from GitHub.

## Safety

Lid closed + heavy CPU/GPU = overheating risk. Built for light long-running jobs.
Use the timer. Read the first-run warning.

## Tech

Swift, SMAppService privileged helper, pmset over XPC. MIT licensed.
```

### Long (Show HN first comment, blog post)

Use the Show HN first-comment template above, plus:

- Link to README "What it runs" section for pmset commands
- Offer to discuss architecture (XPC, code signing requirement, state reconciliation)
- Invite issues and PRs

---

## Messaging do's and don'ts

### Do

- Lead with the **closed-lid moment** (relatable, visual)
- Show the **GIF** — one glance beats a paragraph
- Be **honest about thermal risk** — builds trust
- Put **`brew install` first** in every install mention
- Stay in comments for **2–3 hours** on launch day
- Frame as **"I had this problem, I shipped a fix, open-sourcing it"**

### Don't

- Call it "revolutionary" or "the best keep-awake app"
- Trash Amphetamine or other tools
- Hide or minimize the hardware warning
- Ask friends to mass-star the repo
- Post the same text to 10 subreddits in one day
- Argue with critics — thank them, clarify, move on
- Promise features you won't build

---

## 90-day roadmap (optional stretch goals)

Only if launch goes well and you want more cred — not required for v1.

| Milestone | Effort | Cred value |
|-----------|--------|------------|
| README GIF + Homebrew polish | Low | High |
| Show HN + 1–2 Reddit posts | Low | High |
| awesome-mac PR | Low | Medium |
| `homebrew/cask` PR | Medium | High |
| Blog post: "How I built a SMAppService helper" | Medium | High (dev audience) |
| Save/restore previous pmset sleep value | Medium | User love |
| Custom duration in menu | Low | User love |

Prioritize **maintained + honest** over **feature-rich**.

---

## Launch day runbook

```
T-0 (day before)
  □ Pre-launch checklist complete
  □ GIF live in README
  □ v1.0 release + cask verified
  □ Draft posts ready

T+0 (launch morning, Tue–Thu)
  □ Submit Show HN (8–10 AM ET)
  □ Post first comment immediately
  □ Personal social post with GIF
  □ Monitor HN + GitHub issues for 2–3 hours

T+1 to T+3
  □ Reddit post (one sub) if HN engagement was positive
  □ Reply to all comments and issues

T+7
  □ awesome-mac PR (optional)
  □ Note what worked in this file (update "What we learned" below)

T+30
  □ Review metrics vs. targets
  □ Decide on homebrew/cask PR timing
```

---

## What we learned (fill in after launch)

_Update this section post-launch._

| Channel | Date | Result | Notes |
|---------|------|--------|-------|
| Show HN | | | |
| Reddit | | | |
| Social | | | |
| awesome-mac | | | |

**What resonated:**

**What fell flat:**

**Next time:**

---

## Bottom line

Promotion for Macsomnia is **documenting a useful thing you built**, not running a
marketing campaign. One strong Show HN post, a GIF in the README, honest safety
messaging, and `brew install` at the top of every post will do more for your
reputation than months of low-effort promotion.

Ship it, show it, stay in the comments, keep the repo alive. That's the whole plan.