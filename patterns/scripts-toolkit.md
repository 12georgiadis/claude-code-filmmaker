# Scripts Toolkit

Automation scripts that make Claude Code work as a persistent system rather than a one-shot tool.

## Overview

| Script | Purpose |
|--------|---------|
| `bootstrap.sh` | Set up Claude Code on a new machine from scratch |
| `dashboard.sh` | System overview (tmux, agents, bridge, costs) |
| `heartbeat.sh` | Proactive checks every 30 min (email, calendar, GitHub) |
| `cost-calc.py` | Calculate API-equivalent cost from usage stats |
| `memory-search.sh` | Search through inter-session memory logs |
| `sync.sh` | Git sync of ~/.claude config to a private repo |
| `nosleep.sh` | Prevent Mac from sleeping (for long-running tasks) |
| `resume-sessions.sh` | Restore all tmux windows after a reboot |

## bootstrap.sh

One-command setup for a new machine. Detects OS, installs Node.js, Claude Code CLI, clones config, sets up tmux, mosh, Tailscale, aliases, and cron sync.

```bash
# Run on a fresh machine
curl -sL <raw-github-url>/bootstrap.sh | bash
```

What it does:
1. Detects OS (macOS, Linux, WSL)
2. Installs Node.js via nvm if missing
3. Installs Claude Code CLI via npm
4. Clones your config repo into `~/.claude/`
5. Creates local directories (secrets, cache, logs)
6. Makes all scripts executable
7. Sets up cron for auto-sync every 2 hours
8. Adds shell aliases: `clauded`, `za`/`zb`/`zc`/`zd` (parallel sessions)
9. Installs mosh + tmux if missing
10. Creates a sensible `~/.tmux.conf`

### Parallel session aliases

```bash
alias za='tmux new-window -t claude -n "cc-a" "claude"'
alias zb='tmux new-window -t claude -n "cc-b" "claude"'
alias zc='tmux new-window -t claude -n "cc-c" "claude"'
alias zd='tmux new-window -t claude -n "cc-d" "clauded"'
```

`za`/`zb`/`zc` open Claude Code with interactive permissions. `zd` opens with bypass (`clauded`). All in named tmux windows.

## dashboard.sh

Quick system overview, designed to be called from the Telegram bridge (`/dashboard` command).

Shows:
- Disk usage of `~/.claude/`
- Memory file count
- Cron agent status (loaded, errors, last run)
- Active tmux sessions
- Telegram bridge status
- nosleep (caffeinate) status
- Estimated daily cost

## heartbeat.sh

A proactive agent that runs every 30 minutes via macOS LaunchAgent. It spawns a quick Claude Code session (`--print --no-session-persistence --model haiku`) to check:

- Unread VIP emails (via MCP Gmail)
- Calendar events in the next hour
- GitHub notifications
- Discord DMs and mentions

If something needs attention, it sends a push notification. Otherwise, silent.

```bash
# Install the LaunchAgents
~/.claude/scripts/heartbeat.sh --install

# Check status
~/.claude/scripts/heartbeat.sh --status

# Uninstall
~/.claude/scripts/heartbeat.sh --uninstall
```

Key design decisions:
- Silent hours: 1am-9am (no checks)
- Budget cap: $2 per run (Haiku is cheap)
- Error tracking: alerts after 3 consecutive errors
- Morning digest delegated to a separate script

## cost-calc.py

Reads `~/.claude/stats-cache.json` and calculates what you would have paid on the API. Useful for Max plan users to know if the subscription is worth it.

```bash
python3 ~/.claude/scripts/cost-calc.py
```

Output:
```
## API-equivalent cost

  Opus 4.6      $ 234.56  (in $45.00 | out $123.00 | cache w $50.00 | cache r $16.56)
  Sonnet 4.5    $  12.34  (in $2.00 | out $8.00 | cache w $1.50 | cache r $0.84)
  Haiku 3.5     $   3.21  (in $0.50 | out $2.00 | cache w $0.50 | cache r $0.21)
  TOTAL         $ 250.11

  Per month:
    2026-01  $  89.00  ████████
    2026-02  $ 161.11  ████████████████

  Since 2026-01-15 | 342 sessions
  (estimate based on API pricing, not actual Max cost)
```

## memory-search.sh

Search through inter-session memory logs using Spotlight (fast) with grep fallback.

```bash
# Search by keyword
~/.claude/scripts/memory-search.sh "authentication"

# List recent memory files
~/.claude/scripts/memory-search.sh --recent 10
```

## sync.sh

Git push/pull of `~/.claude/` config to a private repo. Runs automatically every 2 hours via cron (set up by bootstrap.sh).

```bash
~/.claude/scripts/sync.sh push    # commit and push
~/.claude/scripts/sync.sh pull    # pull latest
```

Make sure your `.gitignore` excludes secrets, cache, and other machine-specific files.

## nosleep.sh

Prevents the Mac from sleeping using `caffeinate`. Essential when running long Claude Code tasks overnight or when connected remotely.

```bash
~/.claude/scripts/nosleep.sh      # start
~/.claude/scripts/sleep-ok.sh     # stop (re-enable sleep)
```

Uses a PID file to prevent duplicate processes.

## resume-sessions.sh

After a Mac reboot, all tmux sessions are lost. This script recreates them with `claude --resume <conversation-id>` for each active project.

Structure:
```bash
#!/bin/bash
SESSION="claude-hub"
tmux kill-session -t "$SESSION" 2>/dev/null
tmux new-session -d -s "$SESSION" -n "project-a" -c "$HOME"

# Each project gets a named window with its conversation ID
tmux send-keys -t "$SESSION:project-a" \
  "claude --resume <conversation-id>" ""

tmux new-window -t "$SESSION" -n "project-b"
tmux send-keys -t "$SESSION:project-b" \
  "claude --resume <conversation-id>" ""

# ... repeat for all active projects

tmux select-window -t "$SESSION:project-a"
echo "Sessions restored. Run: tmux attach -t $SESSION"
```

Key points:
- Sessions are **prepared but not launched** (press Enter in each window to start)
- Organized by priority (urgent first)
- Named windows for easy navigation
- Update this script whenever your active projects change
