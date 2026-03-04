# Claude Code Remote Access: The Complete Comparison (2026)

> Every way to run Claude Code from your iPhone, tablet, or another machine — compared.

I run Claude Code on a **Mac Mini M4** in Paris as a 24/7 AI workstation. Over several months I've tested every method to access it remotely from a **MacBook Air M3** or **iPhone 15 Pro Max**. This is a real-world comparison, not a spec sheet.

---

## The Stack

| Layer | Tool |
|-------|------|
| Server | Mac Mini M4 (Paris, always on) |
| Network | Tailscale (mesh VPN) |
| Session persistence | tmux |
| SSH client (iOS) | Blink Shell / Termius |
| Notifications | Custom Telegram bot |
| AI agent layer | OpenClaw / Claude Code Remote Control |

---

## The 6 Methods, Compared

### 1. SSH + tmux (via Blink Shell or Termius)

**What it is:** Connect to your Mac Mini via SSH, attach to a tmux session where Claude Code is running. The classic, battle-tested approach.

**How it works:**
```bash
# From iPhone (Blink or Termius)
ssh user@YOUR_TAILSCALE_IP
tmux attach -t claude
```

| | |
|---|---|
| **Setup** | Medium (SSH keys + tmux config) |
| **Interface** | Terminal only |
| **Reliability** | Excellent |
| **Mobile UX** | Poor (terminal on phone = painful) |
| **Cost** | Free (+ Blink or Termius license) |
| **Offline resilience** | Excellent (tmux survives disconnects) |
| **Full env access** | Yes (filesystem, MCP servers, everything) |

**Best for:** Power users comfortable in the terminal. Not great on a small phone screen.

---

### 2. Blink Shell

**What it is:** The best SSH client for iPhone/iPad. Built on Mosh (mobile shell), which handles network drops far better than raw SSH.

**Key advantages over Termius:**
- Mosh support = stable connections on mobile networks
- Built-in code editor
- Hardware keyboard support
- One-time purchase (~$20) vs Termius subscription

**Key disadvantages:**
- iOS/iPadOS only (no macOS client)
- Still a terminal — no Claude-specific UI
- Font rendering on iPhone is... small

| | |
|---|---|
| **Platform** | iOS / iPadOS only |
| **Price** | ~$20 one-time |
| **Mosh support** | Yes |
| **Best use** | iPad with keyboard |

---

### 3. Termius

**What it is:** Cross-platform SSH client (iOS, macOS, Windows, Android). The "professional" option with team sync.

**Key advantages over Blink:**
- Available on macOS too (unified experience)
- Team sharing of connections
- Nicer UI for managing multiple hosts
- Port forwarding UI

**Key disadvantages:**
- Subscription required for sync (~$10/month)
- No Mosh support (SSH only)
- More "enterprise" than "power user"

| | |
|---|---|
| **Platform** | iOS, macOS, Windows, Android |
| **Price** | Free tier / ~$10/month for sync |
| **Mosh support** | No |
| **Best use** | Multiple devices, team setups |

---

### 4. Telegram: Two Distinct Layers

This is actually two completely separate things that are easy to confuse.

#### 4a. notify.sh — Push Notifications (one-way)

**What it is:** A shell script that fires a push notification when Claude finishes a task. Uses **Pushover** (not Telegram directly), which delivers to iPhone via the Pushover app.

```bash
~/.claude/scripts/notify.sh "Task complete: SEO audit done"
# → Pushover push → iPhone
```

Priorities: `-2` (silent) → `0` (normal) → `2` (emergency, bypasses DND, retries every 30s). Plays a local sound too (Zelda treasure chest). Completely separate from the Telegram bridge.

| | |
|---|---|
| **Direction** | One-way (machine → iPhone) |
| **Full env access** | No |
| **Cost** | Free (Pushover ~$5 one-time) |
| **Reliability** | Excellent |

**Best for:** End-of-task alerts. Fire and forget.

---

#### 4b. telegram-bridge.py — Full Bidirectional Claude Terminal

**What it is:** A custom Python bridge (`telegram-bridge.py`) that connects Telegram to Claude Code on the Mac Mini. You send a message from Telegram → it runs through Claude Code → response comes back to Telegram. A full terminal replacement, from your phone.

```
iPhone Telegram → telegram-bridge.py (Mac Mini) → claude -p "your message" → response → Telegram
```

**What it handles:**
- **Text** → Claude prompt
- **Voice messages** → transcribed via Whisper (whisper-cpp, local) → Claude prompt
- **Photos** → downloaded + sent to Claude with caption
- **Documents** → downloaded + analyzed by Claude
- **Session persistence** — uses `--resume session_id` to maintain context across messages
- **Live status** — sends "⏳ Claude travaille... 42s" updated every 5 seconds while running
- **Commands**: `/reset` (new session), `/session` (show ID), `/stop` (kill bridge)

```bash
# Start the bridge
~/.claude/scripts/telegram-start.sh
# Runs in background, survives terminal close
```

| | |
|---|---|
| **Setup** | Medium (bot token, chat_id, secrets file) |
| **Interface** | Telegram chat (native mobile UX) |
| **Direction** | Fully bidirectional |
| **Full env access** | Yes (runs `claude --dangerously-skip-permissions`) |
| **Voice input** | Yes (Whisper transcription) |
| **Session persistence** | Yes (`--resume`) |
| **Multi-session** | No (one session per bridge instance) |
| **Cost** | Max plan (uses `claude` CLI, same quota) |

**Multi-session extension:** The bridge currently handles one session at a time. To manage multiple Claude sessions from Telegram, you could run multiple bridge instances (one per bot token) or use Telegram Topics (forum threads) to route messages to different sessions — one topic per project.

**Best for:** Full Claude Code access from iPhone without opening a terminal. Voice-to-Claude is particularly powerful.

---

#### 4c. telegram-mcp — Claude Controls Telegram (opposite direction)

**What it is:** An MCP server ([chigwell/telegram-mcp](https://github.com/chigwell/telegram-mcp)) that gives Claude Code programmatic access to your Telegram account. Claude reads and sends Telegram messages as a tool — the direction is reversed from the bridge.

```
Claude Code → telegram-mcp → Telegram API → your chats
```

Not for remote access — for Claude-driven Telegram automations (sending summaries, reading channels, managing groups).

---

### 5. OpenClaw

**What it is:** Open-source, local-first AI agent framework. Originally called Clawdbot (Anthropic trademark issue), then Moltbot, now OpenClaw. Created by Peter Steinberger (PSPDFKit). Went viral in Jan 2026 with 60K GitHub stars in 72h.

**Architecture:** Runs as a Node.js server on your machine. Connects to Claude via API. Has persistent memory (survives sessions), community-built Skills (web browsing, calendar, etc.), and since v2026.2.17, an **iOS Share Extension**.

```
iPhone → iOS Share Extension → OpenClaw server (Mac Mini) → Claude API
```

**vs Claude Code:**
- OpenClaw has persistent memory; Claude Code resets between sessions
- Claude Code wins on deep code refactoring (Opus 4.6 + compaction)
- OpenClaw has 2,857+ community Skills; Claude Code has MCP servers
- OpenClaw is API-based (cost per token); Claude Code is subscription

**Security warning:** CVE-2026-25253 (CVSS 8.8) — WebSocket origin bypass enabling remote code execution. Patch in v2026.2.17. Also: 12% of ClawHub Skills found to be malicious. **Run behind a firewall, not exposed to the internet.**

| | |
|---|---|
| **Setup** | Complex (Node.js server, API keys) |
| **Interface** | Web UI + iOS Share Extension |
| **Persistent memory** | Yes |
| **Cost** | API tokens (variable) |
| **Security** | Risky if exposed publicly |
| **Community** | Massive (199K GitHub stars) |
| **Full env access** | Partial (via Skills) |

**Best for:** People who want persistent AI memory and community integrations. Not a replacement for Claude Code on complex dev tasks.

---

### 6. Claude Code Remote Control ⭐ (Official, New)

**What it is:** Anthropic's official solution (released early 2026, research preview). Runs Claude Code locally on your machine, accessible from claude.ai/code or the Claude iOS/Android app.

**How it works:**
```bash
# On Mac Mini
claude remote-control

# → Displays URL + QR code
# → Open on iPhone: instant connection
```

Or from within an existing session:
```
/remote-control
```

**Key properties:**
- Executes **locally** (not in the cloud) — your filesystem, MCP servers, all configs stay available
- Conversation syncs in real-time across all connected devices
- Survives network drops and machine sleep (reconnects automatically)
- Full claude.ai/code interface on mobile — not a terminal
- **Pro/Max plan only** (not Team/Enterprise)

| | |
|---|---|
| **Setup** | Minimal (`claude remote-control`) |
| **Interface** | claude.ai/code (full web UI) + Claude app |
| **Persistent session** | Yes (survives sleep/disconnect up to ~10min outage) |
| **Cost** | Included in Pro/Max subscription |
| **Full env access** | Yes (MCP servers, filesystem, everything) |
| **Security** | TLS + Anthropic API (no open ports) |
| **Mobile UX** | Excellent (native Claude app) |
| **Limitation** | Terminal must stay open; 1 remote per session |

**Best for:** The default choice. If you're on Max plan, this replaces 90% of SSH terminal use cases.

---

## Head-to-Head Matrix

| | SSH+tmux | Blink | Termius | notify.sh | telegram-mcp | OpenClaw | Remote Control |
|---|---|---|---|---|---|---|---|
| **Setup complexity** | Medium | Easy | Easy | Easy | Medium | Hard | Minimal |
| **Mobile UX** | Poor | OK | OK | Push only | Via Claude | Good | Excellent |
| **Full env access** | Yes | Yes | Yes | No | Yes (MCP) | Partial | Yes |
| **Session persistence** | tmux | tmux | tmux | N/A | N/A | Yes (memory) | Yes |
| **Cost** | Free | $20 | $10/mo | ~$5 one-time | Max plan | API tokens | Max plan |
| **Security** | SSH (solid) | SSH+Mosh | SSH | HTTPS | Session string | ⚠️ CVE risk | TLS/Anthropic |
| **Notifications** | No | No | No | Yes (Pushover) | Via bot | Partial | No |
| **Multi-session** | Yes (tmux) | Yes (tmux) | Yes (tmux) | N/A | N/A | No | No (1 per process) |
| **Official Anthropic** | N/A | N/A | N/A | N/A | N/A | No | Yes |
| **iPad w/ keyboard** | OK | Best | Good | N/A | N/A | OK | Good |

---

## My Recommended Stack (2026)

**Day-to-day single session from iPhone:**
→ **Claude Code Remote Control** (claude.ai/code or Claude app)

**Multiple parallel sessions:**
→ **tmux multi-windows on Mac Mini** — the only solution that scales

**MacBook Air M3 ↔ Mac Mini M4:**
→ **SSH + `tmux attach`** — both machines share the same session state

**End-of-task alerts:**
→ **notify.sh** (Pushover) — fires when Claude finishes, bypasses DND on priority 1+

**Claude automating Telegram:**
→ **telegram-mcp** (MCP server) — Claude reads/sends messages, manages groups as a tool

**Keep OpenClaw for:** persistent memory use cases and community Skills — but behind a firewall, never exposed publicly.

---

## Setup Guides

### Tailscale + SSH baseline
```bash
# Install Tailscale on both machines
# Mac Mini: enable SSH
sudo systemsetup -setremotelogin on
# iPhone: Blink Shell → New Host → YOUR_TAILSCALE_IP
```

### Remote Control (fastest setup)
```bash
# Mac Mini — one command
claude remote-control
# iPhone — scan QR code or open claude.ai/code
```

### tmux persistence
```bash
# Start a named session
tmux new -s claude
# Detach: Ctrl+B then D
# Reattach from anywhere:
tmux attach -t claude
```

### End-of-task notifications (Pushover)
```bash
# notify.sh — fires when Claude finishes a task
# Uses Pushover API (https://pushover.net), not Telegram
~/.claude/scripts/notify.sh "Task done: SEO audit complete" 1
# priority 1 = bypasses DND on iPhone
```

---

## Managing Multiple Sessions Simultaneously

This is the real challenge. Remote Control is excellent for one session — but if you run 3 parallel Claude Code agents, you need a different approach.

### The tmux multi-window pattern (current best solution)

```bash
# On Mac Mini — one tmux session, multiple windows
tmux new-session -s work
# Ctrl+B c   → new window
# Ctrl+B 0/1/2/3 → switch windows
# Ctrl+B ,   → rename window

# Result:
# 0: goldberg    (claude on Goldberg project)
# 1: virus       (claude on Virus project)
# 2: seo         (background SEO task)
# 3: monitor     (logs, status)
```

### MacBook Air M3 ↔ Mac Mini M4 switching

Both machines can be connected to the same tmux session simultaneously via SSH:

```bash
# MacBook Air
ssh your-user@YOUR_TAILSCALE_IP
tmux attach -t work
# → you see exactly the same state as on Mac Mini
```

One writes, one observes. No conflict as long as one device has keyboard focus at a time. You can also open different windows on each device within the same tmux session.

### Remote Control limitation for multi-session

Remote Control supports **one remote connection per Claude Code process**. If you have 3 Claude processes in tmux, you'd need to run `/remote-control` in each one separately and get 3 different URLs. You can then switch between them in the Claude app's session list — but you can't see them side by side.

### Recommended multi-session workflow

| Context | Approach |
|---|---|
| Working at desk | tmux on Mac Mini directly |
| Working from MacBook Air | SSH + `tmux attach` (shared view) |
| Quick check from iPhone | Remote Control on the active session |
| Long background task | tmux + notify.sh alert when done |
| Multiple tasks in parallel | tmux windows (not Remote Control) |

---

## What's Missing (Honest Gaps)

- **No offline access** for any of these (all require network)
- **Remote Control terminal must stay open** — needs tmux or a LaunchAgent wrapper to survive reboots
- **OpenClaw security** is a real concern for production/exposed setups
- **Claude Code on the Web** (cloud-based, different from Remote Control) exists but lacks local filesystem access — not in this comparison

---

## About

This comparison is based on real usage of a Mac Mini M4 as an AI workstation with Claude Code Max plan. Updated February 2026.

Hardware: Mac Mini M4 (server, Paris) + MacBook Air M3 + iPhone 15 Pro Max
Tailscale mesh network, tmux session management, Claude Code Max plan.

---

*Part of my ongoing writing on AI tools for creative and filmmaking workflows.*
*[More at github.com/12georgiadis](https://github.com/12georgiadis)*
