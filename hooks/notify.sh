#!/bin/bash
# claude-power-hooks: notify.sh
# Push notifications + local sound when Claude finishes a task.
#
# Usage: notify.sh "message" [priority] [sound]
#   priority: -2 (silent) | -1 (quiet) | 0 (normal) | 1 (high, bypass DND) | 2 (emergency)
#   sound: any Pushover sound name (gamelan, pushover, magic, cosmic, alien, none)
#
# Setup: create ~/.claude/secrets/pushover.env with:
#   PUSHOVER_TOKEN=your_app_token
#   PUSHOVER_USER=your_user_key
# Optional sounds: ~/.claude/sounds/treasure.wav, ~/.claude/sounds/level-up.wav

source "$(dirname "$0")/platform.sh"

MESSAGE="${1:-Task done}"
PRIORITY="${2:-0}"
PUSH_SOUND="${3:-gamelan}"

# Local sound based on priority
if [ "$PRIORITY" -ge 1 ] 2>/dev/null; then
    play_sound ~/.claude/sounds/level-up.wav 2>/dev/null || play_sound ~/.claude/sounds/treasure.wav
elif [ "$PRIORITY" -le -2 ] 2>/dev/null; then
    : # silent
else
    play_sound ~/.claude/sounds/treasure.wav
fi

# Pushover push notification
if [ -f ~/.claude/secrets/pushover.env ]; then
    source ~/.claude/secrets/pushover.env

    TITLE="Claude Code"
    [ "$PRIORITY" -ge 1 ] && TITLE="Claude Code ⚡"

    ARGS=(
        -F "token=${PUSHOVER_TOKEN}"
        -F "user=${PUSHOVER_USER}"
        -F "message=${MESSAGE}"
        -F "title=${TITLE}"
        -F "priority=${PRIORITY}"
    )

    [ "$PRIORITY" -gt -2 ] && [ "$PUSH_SOUND" != "none" ] && ARGS+=(-F "sound=${PUSH_SOUND}")

    # Emergency: retry every 30s for 5min
    if [ "$PRIORITY" -eq 2 ]; then
        ARGS+=(-F "retry=30" -F "expire=300")
    fi

    curl -s "${ARGS[@]}" https://api.pushover.net/1/messages.json > /dev/null 2>&1
fi

# System notification (except silent)
[ "$PRIORITY" -gt -2 ] && send_notification "${TITLE:-Claude Code}" "$MESSAGE"
