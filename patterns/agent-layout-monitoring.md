# Agent Layout Monitoring

Auto-deploy a multi-pane terminal layout when Claude Code launches subagents, auto-collapse when they finish.

## The Pattern

When you run a complex task with subagents or agent teams, you want to see all of them at once — each in its own visible pane. When they're done, the layout closes itself.

This uses two Claude Code hooks:
- `PreToolUse` on `Task` → deploys the layout on first agent
- `SubagentStop` → collapses when all agents finish

## Terminal Setup

This works best with a terminal that supports programmatic splits. The examples below use **[cmux](https://cmux.dev)** (a Ghostty-based macOS terminal built for AI agents) or Ghostty with the same keybinds.

The layout target:
```
┌──────────────────┬──────────────┐
│                  │  viewport-1  │
│  main session    ├──────────────┤
│  (interactive)   │  viewport-2  │
│                  ├──────────────┤
│                  │  viewport-3  │
└──────────────────┴──────────────┘
```

Each right pane is a **session group viewport** — same tmux session, different window, visible simultaneously.

## tmux: Session Groups

The key tmux concept: multiple sessions can attach to the same group, each showing a different window, all live.

```bash
# Create your main session
tmux new-session -s main-session

# Create viewport sessions (same group)
tmux new-session -s view-1 -t main-session
tmux new-session -s view-2 -t main-session
tmux new-session -s view-3 -t main-session
```

Now `view-1`, `view-2`, `view-3` are independent viewports into `main-session`. Navigate each to a different window to monitor multiple agents simultaneously.

## Hook Scripts

### `~/.claude/scripts/layout-hook-start.sh`

```bash
#!/bin/bash
# Triggered by PreToolUse on Task tool
# Deploys monitoring layout on first agent launch

COUNTER="$HOME/.claude/agent-layout-count"
CURRENT=$(cat "$COUNTER" 2>/dev/null || echo 0)
NEW=$((CURRENT + 1))
echo "$NEW" > "$COUNTER"

# Deploy layout only on first agent (0 → 1)
if [ "$CURRENT" -eq 0 ]; then
    ~/.claude/scripts/layout-agent.sh 3 > /dev/null 2>&1 &
fi
```

### `~/.claude/scripts/layout-hook-stop.sh`

```bash
#!/bin/bash
# Triggered by SubagentStop
# Collapses layout when all agents are done

COUNTER="$HOME/.claude/agent-layout-count"
CURRENT=$(cat "$COUNTER" 2>/dev/null || echo 1)
NEW=$((CURRENT - 1))

if [ "$NEW" -le 0 ]; then
    rm -f "$COUNTER"
    # Only auto-collapse if terminal is not frontmost (avoid interrupting active typing)
    FRONTAPP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
    if [ "$FRONTAPP" != "cmux" ] && [ "$FRONTAPP" != "Ghostty" ]; then
        ~/.claude/scripts/layout-reset.sh > /dev/null 2>&1 &
    fi
else
    echo "$NEW" > "$COUNTER"
fi
```

## settings.json

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Task",
      "hooks": [
        {
          "type": "command",
          "command": "~/.claude/scripts/layout-hook-start.sh",
          "timeout": 5,
          "async": true
        }
      ]
    }
  ],
  "SubagentStop": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "~/.claude/scripts/layout-hook-stop.sh",
          "timeout": 10,
          "async": true
        }
      ]
    }
  ]
}
```

## Manual Controls

| Command | tmux shortcut | What it does |
|---------|---------------|--------------|
| `layout` | `Ctrl+B L` | Standard 4-pane monitoring view |
| `layout-agent 4` | `Ctrl+B A` → `4` | N-pane view for N agents |
| `layout-reset` | `Ctrl+B R` | Back to single pane |
| `Cmd+Shift+F` | — | Zoom/unzoom current pane (hides splits without closing them) |

Add to `~/.tmux.conf`:
```bash
bind L run-shell "~/.claude/scripts/layout.sh"
bind A command-prompt -p "Agents (2-5):" "run-shell '~/.claude/scripts/layout-agent.sh %%'"
bind R run-shell "~/.claude/scripts/layout-reset.sh"
set -g allow-passthrough on  # required for cmux OSC notifications
```

## Why Not Just Watch tmux Windows?

You could. But having the monitoring layout deploy automatically means:
- You don't have to remember to set it up before each big task
- Each agent is visually distinct, not a text list
- The collapse is clean — no stale monitoring panes left open
- Works with agent teams too (same hooks, same counter logic)

## Notes

- The counter file is `~/.claude/agent-layout-count` — delete it manually if a session crashes mid-task
- The layout scripts use AppleScript on macOS. Requires Accessibility permission for your terminal app
- On Linux, replace the `osascript` calls with your compositor's scripting API
