# cmux Session Tracker — Final Cut Style Restore

How to never re-fish session IDs by hand after a cmux crash. Notif on shell start, picker, one keypress, every claude session is back in its workspace.

## The problem

You have 28 cmux workspaces open. Each one runs a `claude` session on a different topic (admin, a film, an inbox triage, a coding project). cmux crashes, or your Mac reboots.

cmux is good at persisting its own structure: workspaces, panels, browsers all come back. But the **shells inside come back empty**. Every claude conversation that was running is gone from view. The conversations themselves still exist in `~/.claude/projects/<encoded-cwd>/<uuid>.jsonl`, but you have no idea which one was running in which workspace.

The official tool `claude --resume` opens an interactive picker, but with 100+ JSONL files in your home cwd, finding the right one for the right workspace is brutal. tmux-resurrect helps but doesn't know about cmux workspaces, and in my setup it had been silently failing for weeks.

## The principle

Track `(cmux_workspace_id, claude_session_id)` pairs as they happen. After a crash, read the tracker, push `claude --resume <id>` into each original workspace via `cmux send`. Done.

This is exactly the model Final Cut Pro uses to recover after a crash, and what Brave does for tabs.

## Architecture

```
~/.zshrc:
  function claude() {
    if CMUX_WORKSPACE_ID && !CLAUDE_TRACKED_PARENT:
      → claude-tracked.sh        (track every start/exit/heartbeat)
        → claude-smart.sh        (your existing failover wrapper, optional)
          → claude binary
    else:
      → fallback (claude-smart, or claude direct)
  }

  if CMUX_WORKSPACE_ID && interactive shell:
    check-restore-on-shell.sh    (debounced, throws macOS notif if pending)
```

Every claude session writes one or more lines to `~/.claude/state/panes.jsonl`:

```json
{"event":"start","ts":"...","session_id":"<uuid>","workspace_id":"29","cwd":"...","pid":12345,"title":"..."}
{"event":"heartbeat","ts":"...","session_id":"<uuid>"}
{"event":"exit_clean","ts":"...","session_id":"<uuid>","exit_code":0}
```

Heartbeats run every 60s in background while claude is alive. If the last event is `start` or `heartbeat` with no `exit_clean`/`exit_crash`, the session is considered restorable.

## Components

| File | Role |
|------|------|
| [`claude-tracked.sh`](../hooks/cmux-tracker/claude-tracked.sh) | Wrapper. Pre-generates a session UUID via `--session-id`, logs start, spawns heartbeat, traps EXIT to log exit_clean / exit_crash |
| [`pane-heartbeat.sh`](../hooks/cmux-tracker/pane-heartbeat.sh) | Background loop, 60s interval, ends when parent dies |
| [`cmux-restore.sh`](../hooks/cmux-tracker/cmux-restore.sh) | Reads tracker, picker UI, `cmux send "claude --resume <id>"` per workspace. Modes: `--list`, `--auto`, `--notify`, `--max-age N` |
| [`check-restore-on-shell.sh`](../hooks/cmux-tracker/check-restore-on-shell.sh) | .zshrc hook. On interactive shell inside cmux, debounced 5min, fires `--notify` |
| [`SCHEMA.md`](../hooks/cmux-tracker/SCHEMA.md) | Tracker file format |

All scripts use `$HOME` and standard env vars. No hardcoded paths.

## Why a custom UUID

`claude --session-id <uuid>` lets the wrapper know the session ID before claude writes its first JSONL line. Without it, you'd have to scan the projects folder after the fact and match by timestamp, which is fragile.

## Setup

```bash
# 1. Place scripts (or clone this repo and symlink)
mkdir -p ~/.claude/scripts/cmux-tracker ~/.claude/state ~/.claude/logs
cp hooks/cmux-tracker/*.sh ~/.claude/scripts/cmux-tracker/
cp hooks/cmux-tracker/SCHEMA.md ~/.claude/state/
chmod +x ~/.claude/scripts/cmux-tracker/*.sh
touch ~/.claude/state/panes.jsonl

# 2. Add to ~/.zshrc
cat >> ~/.zshrc <<'EOF'

# cmux session tracker
claude() {
    if [ -n "$CMUX_WORKSPACE_ID" ] && [ -z "$CLAUDE_TRACKED_PARENT" ]; then
        ~/.claude/scripts/cmux-tracker/claude-tracked.sh "$@"
    else
        command claude "$@"
    fi
}
alias cmux-restore='~/.claude/scripts/cmux-tracker/cmux-restore.sh'

# Notif on shell start if sessions are pending restore
if [ -n "$CMUX_WORKSPACE_ID" ] && [ -o interactive ]; then
    ~/.claude/scripts/cmux-tracker/check-restore-on-shell.sh
fi
EOF

# 3. (optional) Add cmux to macOS Login Items so it relaunches after Mac reboot
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/cmux.app", hidden:false}'
```

If you already have a `claude-smart.sh` (Bedrock failover, etc.), edit `claude-tracked.sh` to chain through it instead of calling the binary directly. The script already checks for `~/.claude/scripts/claude-smart.sh` and cascades automatically.

## Daily workflow

Nothing changes. You type `claude` like always. The tracking happens silently.

## After a crash

1. cmux relaunches (auto via Login Items, or manually).
2. You open any workspace → first interactive shell triggers a debounced notif: *"N sessions to restore"*.
3. You type `cmux-restore` → numbered picker:

   ```
   ═══ 6 session(s) restorable ═══

     [ 1] WS:29  | 12min | budget review
          claude --resume 020137d1-0db8-4081-9357-6ff5d1c796a6
     [ 2] WS:30  | 12min | venue follow-up
          claude --resume 28c5e1d7-4ebb-499b-906c-01a191827389
     [ 3] WS:34  | 49min | infra failover setup
          claude --resume 5599ed0b-1dc1-45e6-953c-a62e0be88a63
     ...

   > 1 2 3   (or `all`, or `q`)
   ```

4. The script pushes `claude --resume <id>` into each selected cmux workspace via `cmux send`. Sessions reappear in their original visual context.

## What you can do from iPhone

| State | What works |
|-------|------------|
| Mac up, cmux up, you SSH in | `cmux-restore` works from any shell. Notif stays on the Mac (no push). |
| Mac up, cmux down | `open -a cmux` via SSH if a graphical user session exists. Then SSH in fresh, get the notif. |
| Mac up, cmux down, can't relaunch | `cmux-restore.sh --list` works. Then `claude --resume <id>` manually in a tmux SSH session. You lose the cmux workspace layout but recover the conversation. |
| Mac asleep / off | Wake-on-LAN via Tailscale, or wait. Nothing works until the Mac is up. |

For real iPhone push notifications when sessions are pending, integrate `ntfy.sh` or Pushover into `cmux-restore.sh --notify`. Left as future work.

## Why not tmux-resurrect

tmux-resurrect saves tmux pane state and can restore the last command per pane. It's plugin-based and depends on `tmux capture-pane` succeeding inside an interactive context. In my setup the cron-based backup was logging "OK" silently while saving nothing for weeks (cron doesn't have an attached tmux client).

The custom tracker is:
- **Aware of cmux**, not just tmux: it logs `workspace_id` and `surface_id`, so restoration goes back to the visual location
- **Append-only JSONL**: trivial to parse, debug, or extend
- **Heartbeat-based**: distinguishes clean exits from crashes
- **No plugin loop dependency**: a single shell script in the cron, self-contained

I left tmux-resurrect installed as a fallback, just removed the cron entry.

## Limits

- The tracker doesn't know about non-claude long-running processes. If you had `jupyter`, a dev server, or `mosh` running, those are not tracked. Add a similar wrapper if needed.
- If claude is killed by SIGKILL (no chance to run trap EXIT), the session shows as "stale" (no heartbeat for >5min) but `cmux-restore.sh` still proposes it (any non-clean-exit session is a candidate).
- Workspaces that had a claude session but where claude was killed before writing its first JSONL won't restore via `--resume <id>` (the file doesn't exist). They'll show in the picker but `claude --resume` will fail. Edge case, rare.

## Related patterns

- [resume-sessions](resume-sessions.md) — manual reboot-recovery script (predates this one)
- [tmux-survival](tmux-survival.md) — never run claude without a session manager
- [ghostty-cmux](ghostty-cmux.md) — terminal layer choices

## Source

Scripts in [`hooks/cmux-tracker/`](../hooks/cmux-tracker/). MIT.
