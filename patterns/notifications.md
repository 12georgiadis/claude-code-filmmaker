# Notification System

Get notified when Claude Code finishes a task, wherever you are.

## The problem

Claude Code runs in a terminal. If you're on your phone, in another app, or away from your desk, you miss when it's done. You end up checking back constantly or forgetting entirely.

## The solution

A simple notification script that Claude Code calls at the end of tasks. Two layers:

1. **Local**: macOS sound (the Zelda treasure chest sound, because why not)
2. **Remote**: push notification via Pushover (arrives on your phone)

## Implementation

### notify.sh

```bash
#!/bin/bash
# Claude Code notification: sound + push
source ~/.claude/secrets/pushover.env

MESSAGE="${1:-Task done!}"

# Play a sound (macOS)
afplay ~/.claude/sounds/treasure.wav 2>/dev/null &

# Send push notification via Pushover
curl -s \
  -F "token=${PUSHOVER_TOKEN}" \
  -F "user=${PUSHOVER_USER}" \
  -F "message=${MESSAGE}" \
  -F "title=Claude Code" \
  -F "sound=gamelan" \
  https://api.pushover.net/1/messages.json > /dev/null 2>&1
```

### Alternative: notify-task-done.sh (simpler, no external service)

```bash
#!/bin/zsh
# macOS-only: native notification + beep
osascript -e "display notification \"$1\" with title \"Claude Code\" sound name \"Glass\""
osascript -e 'beep 3'
echo "[$(date)] TASK DONE: $1" >> ~/.claude/logs/notifications.log
```

This one uses macOS native notifications which sync to iPhone via iCloud (if Handoff/Continuity is enabled).

## Setup

### Option A: Pushover (recommended for remote)

1. Install [Pushover](https://pushover.net/) on your phone ($5 one-time)
2. Create an application in the Pushover dashboard
3. Create the secrets file:

```bash
cat > ~/.claude/secrets/pushover.env << 'EOF'
PUSHOVER_TOKEN=your_app_token
PUSHOVER_USER=your_user_key
EOF
```

### Option B: Telegram (if you already have the bridge)

Replace the push notification part with a Telegram API call:

```bash
curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "text=${MESSAGE}" > /dev/null 2>&1
```

### Option C: macOS only (no setup)

Just use `notify-task-done.sh` which requires nothing external.

## How Claude Code uses it

In CLAUDE.md, the notification preference is declared:

```markdown
## Preferences
- Notification on task completion: `~/.claude/scripts/notify.sh 'message'`
```

Claude Code then calls it via bash when finishing significant work:

```bash
~/.claude/scripts/notify.sh "Build complete, all tests passing"
```

## Custom sounds

Put any `.wav` or `.mp3` file in `~/.claude/sounds/` and reference it in the script. The Zelda treasure chest sound is a satisfying choice for completed tasks. Find it on the internet, it's everywhere.
