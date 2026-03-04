#!/bin/bash
# layout-hook-start.sh — PreToolUse:Task
# Incrémente le compteur d'agents + rebuild layout avec debounce 800ms

COUNTER="$HOME/.claude/agent-layout-count"
TRIGGER="$HOME/.claude/agent-layout-trigger"

# Incrémenter
CURRENT=$(cat "$COUNTER" 2>/dev/null || echo 0)
NEW=$((CURRENT + 1))
echo "$NEW" > "$COUNTER"

# ID unique pour ce déclenchement (PID + epoch)
TRIGGER_ID="$$_$(date +%s)"
echo "$TRIGGER_ID" > "$TRIGGER"

# Debounce 800ms : seul le dernier appel reconstruit le layout
(
    sleep 0.8
    CURRENT_TRIGGER=$(cat "$TRIGGER" 2>/dev/null)
    if [ "$CURRENT_TRIGGER" = "$TRIGGER_ID" ]; then
        N=$(cat "$COUNTER" 2>/dev/null || echo 1)
        ~/.claude/scripts/layout-agent.sh "$N" > /dev/null 2>&1
    fi
) &
