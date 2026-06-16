#!/bin/bash
# claude-tracked.sh — Wrapper claude qui enregistre chaque session par workspace cmux.
#
# Architecture (2026-05-14) : Final Cut style restore après crash.
#   - Capture CMUX_WORKSPACE_ID + CMUX_SURFACE_ID dans l'env.
#   - Pre-genere un UUID et le passe à claude via --session-id pour connaître
#     l'ID avant que claude écrive son JSONL.
#   - Logue start dans ~/.claude/state/panes.jsonl.
#   - Lance pane-heartbeat.sh en background pour marquer la session vivante.
#   - Trap EXIT pour logguer exit_clean ou exit_crash.
#
# Usage : claude-tracked.sh [args claude...]
#   ex : claude-tracked.sh --dangerously-skip-permissions
#        claude-tracked.sh --resume 020137d1-... --dangerously-skip-permissions
#
# Si pas dans cmux (pas de CMUX_WORKSPACE_ID) : passthrough direct, pas de tracking.
# Si déjà dans claude-tracked (CLAUDE_TRACKED_PARENT set) : passthrough pour éviter loop.

set -uo pipefail

CLAUDE_BIN="${CLAUDE_BIN:-/opt/homebrew/bin/claude}"
STATE_FILE="$HOME/.claude/state/panes.jsonl"
HEARTBEAT_BIN="$HOME/.claude/scripts/cmux-tracker/pane-heartbeat.sh"
LOG="$HOME/.claude/logs/claude-tracked.log"
mkdir -p "$(dirname "$STATE_FILE")" "$(dirname "$LOG")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

# --- Passthrough si pas dans cmux OU déjà wrapped ---------------------------
if [ -z "${CMUX_WORKSPACE_ID:-}" ] || [ -n "${CLAUDE_TRACKED_PARENT:-}" ]; then
    exec "$CLAUDE_BIN" "$@"
fi

# --- Détecte si --resume <id> est déjà passé --------------------------------
SESSION_ID=""
HAS_RESUME=0
ARGS=("$@")
for ((i=0; i<${#ARGS[@]}; i++)); do
    case "${ARGS[$i]}" in
        --resume|-r)
            HAS_RESUME=1
            # Le prochain arg est l'ID si présent et pas une option
            next_idx=$((i+1))
            if [ $next_idx -lt ${#ARGS[@]} ] && [[ "${ARGS[$next_idx]}" =~ ^[a-f0-9-]{36}$ ]]; then
                SESSION_ID="${ARGS[$next_idx]}"
            fi
            ;;
        --resume=*)
            HAS_RESUME=1
            val="${ARGS[$i]#--resume=}"
            [[ "$val" =~ ^[a-f0-9-]{36}$ ]] && SESSION_ID="$val"
            ;;
        --session-id)
            next_idx=$((i+1))
            [ $next_idx -lt ${#ARGS[@]} ] && SESSION_ID="${ARGS[$next_idx]}"
            ;;
        --session-id=*)
            SESSION_ID="${ARGS[$i]#--session-id=}"
            ;;
    esac
done

# --- Si nouvelle session : pre-generate UUID --------------------------------
if [ -z "$SESSION_ID" ] && [ "$HAS_RESUME" -eq 0 ]; then
    SESSION_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    ARGS+=(--session-id "$SESSION_ID")
fi

# --- Récupère le titre du workspace via cmux --------------------------------
WS_TITLE=""
if command -v cmux >/dev/null 2>&1; then
    WS_TITLE=$(cmux list-workspaces 2>/dev/null \
        | awk -v ws="workspace:$CMUX_WORKSPACE_ID" '$0 ~ ws {sub(/^[* ]+workspace:[0-9]+[ \t]+/,""); sub(/[ \t]*\[selected\][ \t]*$/,""); print; exit}')
fi

# --- Logue start ------------------------------------------------------------
ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
cwd=$(pwd)
pid=$$
args_str=$(printf '%s ' "$@" | sed 's/ $//')

python3 -c "
import json
print(json.dumps({
    'event': 'start',
    'ts': '$ts',
    'session_id': '$SESSION_ID',
    'workspace_id': '${CMUX_WORKSPACE_ID:-}',
    'surface_id': '${CMUX_SURFACE_ID:-}',
    'cwd': '$cwd',
    'pid': $pid,
    'title': '''$WS_TITLE''',
    'args': '''$args_str''',
    'has_resume': bool($HAS_RESUME),
}))" >> "$STATE_FILE"

log "start session=$SESSION_ID ws=$CMUX_WORKSPACE_ID title=$WS_TITLE"

# --- Lance heartbeat en background ------------------------------------------
if [ -x "$HEARTBEAT_BIN" ]; then
    "$HEARTBEAT_BIN" "$SESSION_ID" "$pid" &
    HEARTBEAT_PID=$!
    log "heartbeat pid=$HEARTBEAT_PID for session=$SESSION_ID"
fi

# --- Trap EXIT pour logguer la fin ------------------------------------------
cleanup() {
    local exit_code=$?
    local end_ts
    end_ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local event="exit_clean"
    [ "$exit_code" -ne 0 ] && event="exit_crash"
    python3 -c "
import json
print(json.dumps({
    'event': '$event',
    'ts': '$end_ts',
    'session_id': '$SESSION_ID',
    'exit_code': $exit_code,
}))" >> "$STATE_FILE"
    log "$event session=$SESSION_ID code=$exit_code"
    [ -n "${HEARTBEAT_PID:-}" ] && kill "$HEARTBEAT_PID" 2>/dev/null
}
trap cleanup EXIT INT TERM

# --- Lance claude (cascade via claude-smart si présent pour fallback Bedrock) -
export CLAUDE_TRACKED_PARENT="$SESSION_ID"
SMART="$HOME/.claude/scripts/claude-smart.sh"
if [ -x "$SMART" ]; then
    "$SMART" claude "${ARGS[@]}"
else
    "$CLAUDE_BIN" "${ARGS[@]}"
fi
