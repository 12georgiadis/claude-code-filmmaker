# Resume Sessions After Reboot

Restore all your Claude Code sessions after a Mac reboot using a single script.

## The problem

tmux sessions don't survive a reboot. If you had 10+ active Claude Code conversations across different projects, they're all gone. Claude Code conversations are saved (you can list them with `claude conversations list`), but reconnecting each one manually in separate tmux windows is tedious.

## The solution

A bash script that recreates your entire tmux workspace: named windows, organized by priority, each pre-loaded with `claude --resume <conversation-id>`.

## How to use

```bash
# After reboot
bash ~/resume-sessions.sh
tmux attach -t claude-hub
# Then press Enter in each window to actually launch
```

## The script template

```bash
#!/bin/bash
SESSION="claude-hub"

# Kill existing session if any
tmux kill-session -t "$SESSION" 2>/dev/null

# Create session with first window
tmux new-session -d -s "$SESSION" -n "project-a" -c "$HOME"

# === PRIORITY 1: URGENT ===

tmux send-keys -t "$SESSION:project-a" \
  "claude --resume <conversation-id>" ""

tmux new-window -t "$SESSION" -n "project-b"
tmux send-keys -t "$SESSION:project-b" \
  "claude --resume <conversation-id>" ""

# === PRIORITY 2: IMPORTANT ===

tmux new-window -t "$SESSION" -n "project-c"
tmux send-keys -t "$SESSION:project-c" \
  "claude --resume <conversation-id>" ""

# === PRIORITY 3: CAN WAIT ===

tmux new-window -t "$SESSION" -n "project-d"
tmux send-keys -t "$SESSION:project-d" \
  "claude --resume <conversation-id>" ""

# Go to first window
tmux select-window -t "$SESSION:project-a"

echo ""
echo "=== SESSIONS RESTORED ==="
echo "Windows prepared in session '$SESSION'"
echo ""
echo "Connect: tmux attach -t $SESSION"
echo ""
echo "Navigation:"
echo "  Ctrl+B w     = list all windows"
echo "  Ctrl+B n/p   = next/previous window"
echo "  Ctrl+B 0-9   = go to window N"
echo ""
echo "IMPORTANT: Sessions are PREPARED but NOT launched."
echo "Press Enter in each window to start the resume."
```

## Finding conversation IDs

```bash
# List recent conversations
claude conversations list

# Or search by keyword in the conversation
claude conversations list | grep -i "project-name"
```

## Key design decisions

1. **Prepared but not launched.** The script types the command but doesn't press Enter. This lets you choose which sessions to actually resume (they each cost API tokens).

2. **Organized by priority.** Urgent projects first, nice-to-haves last. You process them in order.

3. **Named windows.** Each window has a descriptive name (`seo`, `budget`, `telegram-bridge`) so you can navigate with `Ctrl+B w`.

4. **Single session, multiple windows.** One tmux session called `claude-hub` with all your work inside. Easier to manage than separate sessions.

## Maintenance

Update the script whenever your active projects change:
- Finished a project? Remove its window.
- Started a new one? Add a window with the conversation ID.
- Project became urgent? Move it up in priority.

You can also have Claude Code generate/update this script for you based on your backlog.

## Combining with the Telegram bridge

After running resume-sessions.sh, start the Telegram bridge in a separate window:

```bash
tmux new-window -t claude-hub -n "telegram-bridge"
tmux send-keys -t "claude-hub:telegram-bridge" \
  "bash ~/.claude/scripts/telegram-start.sh" C-m
```

Now you can control all restored sessions from your phone.
