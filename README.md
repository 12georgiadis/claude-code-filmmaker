<p align="center">
  <img src="assets/header-banner.jpg" alt="Claude Code Filmmaker" width="100%"/>
</p>

Not a developer tutorial. Not a prompt engineering guide. This is a real, opinionated setup built by an artist who uses Claude Code every day for filmmaking, creative tools, and vibe coding.

**Config. Patterns. Hooks. Remote access. Everything in one place.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Claude Code](https://img.shields.io/badge/Claude_Code-Opus_4.6-blueviolet?style=flat-square)
![Skills](https://img.shields.io/badge/Skills-109-green?style=flat-square)
![Personas](https://img.shields.io/badge/Agent_Personas-38-orange?style=flat-square)

---

## Context

I'm [Ismaël Joffroy Chandoutis](https://ismaeljoffroychandoutis.com), a filmmaker and artist based in Paris. I work across cinema, contemporary art, and new media. I'm not a developer. I use Claude Code as a creative and technical partner to build tools, automate workflows, and explore AI as an artistic method.

This repo documents the actual configuration, decisions, and patterns that emerged from daily usage since January 2026. Everything here is tested in production (my production, which is making films and art).

**César 2022** best short documentary. Selected at **Cannes**, **IDFA**, **Hot Docs**, **Annecy**. Honorary Mention **Ars Electronica**.

---

## What's inside

```
claude-code-filmmaker/
├── config/       # CLAUDE.md structure, settings.json annotated
├── patterns/     # 14 reusable patterns (tmux, memory, notifications, agent teams...)
├── hooks/        # Push notifications, auto tab naming, tmux layout management
├── remote/       # Every way to run Claude Code remotely — compared
├── setup/        # Full inventory: 109 skills, 38 personas, 40+ plugins
├── essays/       # Writing from this practice
├── journal/      # Decisions log
└── sources/      # Articles and threads that shaped the setup
```

---

## Config

How the agent is configured, and why.

| File | What it covers |
|------|---------------|
| [CLAUDE.md structure](config/claude-md-structure.md) | The global instructions file: identity, workflows, 7 quality rules (anti-hallucination, scrap-and-redo, self-updating rules, confrontation mode...) |
| [Settings explained](config/settings-explained.md) | Every `settings.json` choice annotated: privacy (telemetry off), deny rules (minimal: only block the irreversible), statusline, agent teams, extended thinking |

**Key decisions:**
- Deny rules are minimal by design: only block irreversible commands. The `claude` (interactive permissions) vs `clauded` (bypass) separation handles daily control.
- Telemetry fully disabled (Trail of Bits approach).
- Extended thinking always on.
- Conversation history kept 365 days instead of 30.

---

## Patterns

14 reusable patterns, decision frameworks, and automation scripts.

| Pattern | What it solves |
|---------|---------------|
| [Max Plan vs API](patterns/max-vs-api.md) | When Claude Code Max ($200/mo) pays off vs API. Real usage data and breakeven analysis. |
| [tmux Survival Guide](patterns/tmux-survival.md) | Never lose a session. Multi-machine setup, remote access, recovery after reboot. |
| [Telegram Bridge](patterns/telegram-bridge.md) | Control Claude Code from your phone via Telegram. Bidirectional: text, voice, images, files. |
| [Notifications](patterns/notifications.md) | Get notified when tasks finish. Sound (Zelda!) + push (Pushover/Telegram/macOS). |
| [Statusline](patterns/statusline.md) | Two-line status bar: model, context usage, cost, duration, cache %, lines changed. |
| [Scripts Toolkit](patterns/scripts-toolkit.md) | All automation scripts: bootstrap, dashboard, heartbeat, cost calculator, memory search. |
| [Memory System](patterns/memory-system.md) | Persistent memory across sessions. Daily logs, backlog tracking, Spotlight search. |
| [Resume Sessions](patterns/resume-sessions.md) | Restore all tmux windows after a reboot with `claude --resume`. One script. |
| [Cross-Platform](patterns/cross-platform.md) | macOS, Linux, Windows (WSL2). Platform abstraction layer and setup guide. |
| [Agent Layout Monitoring](patterns/agent-layout-monitoring.md) | Monitor subagent activity in real-time. Split-pane layout, tmux hooks, live tail. |
| [Multi-Machine Setup](patterns/multi-machine.md) | MacBook + Mac Mini + PC on Tailscale. SSH/mosh, git sync, source of truth. |
| [Ghostty + cmux](patterns/ghostty-cmux.md) | GPU terminal + native tmux. Auto-restore all windows on reboot, no AppleScript. |
| [Agent Teams](patterns/agent-teams.md) | Peer-to-peer multi-agent coordination. Task list sharing, messaging, shutdown flow. |
| [VO Analysis Pipeline](patterns/vo-analysis-pipeline.md) | Voice-over analysis for documentary production. Local ASR → Gemini → codex update. |

---

## Hooks

Drop-in automation scripts for Claude Code hooks.

| Script | What it does |
|--------|-------------|
| [notify.sh](hooks/notify.sh) | Push notifications (Pushover/Telegram) + sound on task completion |
| [tab-title.sh](hooks/tab-title.sh) | Auto-rename terminal tab to current project name |
| [layout-hook-start.sh](hooks/layout-hook-start.sh) | Expand tmux layout when subagents spawn |
| [layout-hook-stop.sh](hooks/layout-hook-stop.sh) | Collapse layout + notify when all agents finish |
| [platform.sh](hooks/platform.sh) | Cross-platform detection (macOS/Linux/WSL2) |

**Install:**

```bash
cp hooks/*.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/*.sh
```

---

## Remote Access

[Every way to run Claude Code remotely](remote/access-guide.md) — from iPhone, tablet, or another machine. Real-world comparison, not a spec sheet.

| Method | Mobile UX | Reliability | Setup |
|--------|-----------|-------------|-------|
| SSH + tmux (Blink/Termius) | Poor | Excellent | Medium |
| Mosh + tmux | Fair | Best | Medium |
| Telegram Bot Bridge | Good | Good | High |
| OpenClaw (iOS app) | Good | Good | Low |
| Claude Remote Control | Best | Beta | Low |
| Remote Desktop (AnyDesk/Jump) | Fair | Good | Low |

---

## Setup Overview

The full inventory. [Detailed breakdown →](setup/overview.md)

| Component | Count |
|---|---|
| Official plugins | 40+ |
| Custom skills | 109 |
| Agent personas | 38 (filmmakers, philosophers, artists) |
| Custom slash commands | 16 |
| Custom MCP servers | 3 |
| Automation scripts | 30+ |

---

## Core Principles

**AI as alteration, not augmentation.** The agent isn't here to make me faster. It's here to make the work different from what I would have done alone.

**Specs before code.** Every project starts with an interview phase. No implementation without specs. Two custom skills enforce this: `/interview` and `/pitch`.

**7 quality rules** baked into CLAUDE.md:

1. **Anti-hallucination** — never use simulated, invented, or approximate data
2. **Return to plan mode** — if a fix fails, stop. Don't spiral. Re-plan.
3. **Scrap and redo** — when output is mediocre, restart from scratch with accumulated context
4. **Self-update** — the agent updates its own rules after every significant error
5. **Use subagents** — parallelize complex tasks, keep main context clean
6. **Verify your work** — never say "done" without proof
7. **Confrontation mode** — challenge choices, say no when justified

---

## Stack

| Layer | Tools |
|-------|-------|
| **AI** | Claude Code Max ($200/mo), Opus 4.6 + Sonnet 4.6, Agent Teams |
| **Terminal** | Ghostty (GPU), tmux, cmux |
| **Hardware** | MacBook Air M3 + Mac Mini M4 (24/7) + PC RTX 5090 |
| **Network** | Tailscale mesh VPN, mosh |
| **Mobile** | Telegram bot, Blink Shell (SSH), Remote Control |
| **Self-hosted** | ComfyUI (GPU), social media scheduling |
| **Memory** | BACKLOG.md, session logs, Spotlight search |

---

## Essays

| Essay | Topic |
|-------|-------|
| [On Agentic Engineering](essays/2026-02-25-on-agentic-engineering.md) | Notes from a filmmaker who's been through multiple technological ruptures — and recognizes this one. |

## Journal

| Entry | Topic |
|-------|-------|
| [Genesis](journal/2026-02-15-genesis.md) | Day zero. Full audit against gmoney.eth's 25 tips. Resulted in 7 new rules, statusline, deny rules, memory logs. |

## Sources

| Source | What we learned |
|--------|----------------|
| [gmoney.eth — 25 lessons](sources/2026-02-15-gmoney-25-tips.md) | Each tip scored: implemented, explored, or decided against. |
| [Karpathy — Vibe Coding](sources/2025-02-02-karpathy-vibe-coding.md) | The original tweet (6.7M views). Why this repo makes vibe coding sustainable. |

---

## Influences

- [Trail of Bits](https://github.com/trailofbits/claude-code-config) — opinionated security defaults
- [@bcherny](https://x.com/bcherny) (Claude Code creator) — team tips
- [@gmoneyNFT](https://x.com/gmoneyNFT) — 25 lessons from daily multi-agent usage
- [@__BOMO](https://x.com/__BOMO) — context window statusline

---

*This is not a template to copy. It's a reference for people building their own relationship with an AI coding tool — especially non-developers using it for creative work.*
