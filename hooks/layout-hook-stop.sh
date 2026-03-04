#!/bin/bash
# layout-hook-stop.sh — SubagentStop
# Décrémente le compteur. Collapse le layout quand tous les agents sont terminés.

COUNTER="$HOME/.claude/agent-layout-count"
TRIGGER="$HOME/.claude/agent-layout-trigger"

CURRENT=$(cat "$COUNTER" 2>/dev/null || echo 1)
NEW=$((CURRENT - 1))

if [ "$NEW" -le 0 ]; then
    rm -f "$COUNTER" "$TRIGGER"
    FRONTAPP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
    if [ "$FRONTAPP" != "cmux" ]; then
        ~/.claude/scripts/layout-reset.sh > /dev/null 2>&1 &
    fi
    ~/.claude/scripts/notify.sh "Agents terminés" 0 "magic" &
else
    echo "$NEW" > "$COUNTER"
fi
