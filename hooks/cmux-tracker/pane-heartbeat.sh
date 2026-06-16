#!/bin/bash
# pane-heartbeat.sh — Marque une session claude vivante toutes les 60s.
# Lancé en background par claude-tracked.sh. Termine quand le PID parent meurt.
#
# Usage : pane-heartbeat.sh <session_id> <parent_pid>

set -uo pipefail

SESSION_ID="${1:?session_id requis}"
PARENT_PID="${2:?parent_pid requis}"
STATE_FILE="$HOME/.claude/state/panes.jsonl"
INTERVAL=60

# Détache du parent shell pour ne pas être tué par le SIGHUP
trap '' HUP

while true; do
    # Le parent est-il vivant ?
    if ! kill -0 "$PARENT_PID" 2>/dev/null; then
        exit 0
    fi
    ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    printf '{"event":"heartbeat","ts":"%s","session_id":"%s"}\n' "$ts" "$SESSION_ID" >> "$STATE_FILE"
    sleep "$INTERVAL"
done
