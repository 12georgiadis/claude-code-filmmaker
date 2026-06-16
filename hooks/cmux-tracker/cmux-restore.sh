#!/usr/bin/env bash
# cmux-restore.sh — Restaure les sessions claude après crash cmux.
#
# Lit ~/.claude/state/panes.jsonl, identifie les sessions actives au moment
# du crash (status start/heartbeat sans exit_clean ni exit_crash récent),
# et propose un picker pour relancer claude --resume <id> dans chaque workspace
# via cmux send.
#
# Usage :
#   cmux-restore.sh                  # picker interactif
#   cmux-restore.sh --list           # juste lister, ne rien faire
#   cmux-restore.sh --auto           # restaure tout sans demander (dangereux)
#   cmux-restore.sh --notify         # notif macOS si sessions à restaurer
#   cmux-restore.sh --max-age N      # ne considère que les sessions < N min (défaut 1440)

set -uo pipefail

STATE_FILE="$HOME/.claude/state/panes.jsonl"
CMUX_BIN="${CMUX_BIN:-/Applications/cmux.app/Contents/Resources/bin/cmux}"
MAX_AGE_MIN=1440  # 24h par défaut
MODE="picker"

# --- Args -------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --list) MODE="list"; shift ;;
        --auto) MODE="auto"; shift ;;
        --notify) MODE="notify"; shift ;;
        --max-age) MAX_AGE_MIN="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'
            exit 0 ;;
        *) echo "Option inconnue : $1"; exit 2 ;;
    esac
done

[ ! -f "$STATE_FILE" ] && { echo "Aucun tracker trouvé : $STATE_FILE"; exit 0; }

# --- Construit la liste des sessions actives via Python ---------------------
read -r -d '' PYCODE <<'PYEOF' || true
import json, sys, os
from datetime import datetime, timezone, timedelta

state_file = sys.argv[1]
max_age_min = int(sys.argv[2])
now = datetime.now(timezone.utc)
cutoff = now - timedelta(minutes=max_age_min)

# Track le dernier état de chaque session
sessions = {}  # session_id -> dict
with open(state_file) as fh:
    for line in fh:
        line = line.strip()
        if not line: continue
        try:
            ev = json.loads(line)
        except: continue
        sid = ev.get('session_id')
        if not sid: continue
        if sid not in sessions:
            sessions[sid] = {'session_id': sid, 'last_ts': None, 'last_event': None}
        s = sessions[sid]
        if ev.get('event') == 'start':
            s.update({k: ev.get(k) for k in ('workspace_id','surface_id','cwd','pid','title','args','has_resume')})
        ts = ev.get('ts')
        if ts:
            s['last_ts'] = ts
            s['last_event'] = ev.get('event')
            if 'exit_code' in ev:
                s['exit_code'] = ev['exit_code']

# Filtre : actives = pas exit_clean / pas exit_crash, et heartbeat / start dans la fenêtre
active = []
for sid, s in sessions.items():
    if not s.get('last_event'): continue
    if s['last_event'] in ('exit_clean', 'exit_crash'): continue
    if not s.get('workspace_id'): continue
    try:
        last_dt = datetime.fromisoformat(s['last_ts'].replace('Z','+00:00'))
    except: continue
    if last_dt < cutoff: continue
    age_min = int((now - last_dt).total_seconds() / 60)
    s['age_min'] = age_min
    active.append(s)

# Tri par age croissant (plus récent en premier)
active.sort(key=lambda x: x['age_min'])

print(json.dumps(active))
PYEOF

ACTIVE_JSON=$(python3 -c "$PYCODE" "$STATE_FILE" "$MAX_AGE_MIN")
COUNT=$(echo "$ACTIVE_JSON" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

if [ "$COUNT" -eq 0 ]; then
    case "$MODE" in
        notify) ;;  # silent si rien à restaurer
        *) echo "Aucune session active à restaurer." ;;
    esac
    exit 0
fi

# --- Mode notify : juste signaler -------------------------------------------
if [ "$MODE" = "notify" ]; then
    osascript -e "display notification \"$COUNT session(s) à restaurer. Tape: cmux-restore\" with title \"cmux crash recovery\" sound name \"Tink\""
    exit 0
fi

# --- Affiche la liste -------------------------------------------------------
echo ""
echo "═══ $COUNT session(s) restaurable(s) ═══"
echo ""
echo "$ACTIVE_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for i, s in enumerate(data):
    title = (s.get('title') or '?')[:50]
    ws = s.get('workspace_id','?')
    age = s.get('age_min', 0)
    sid = s['session_id']
    age_str = f'{age}min' if age < 60 else f'{age//60}h{age%60:02d}'
    print(f'  [{i+1:2d}] WS:{ws:<3} | {age_str:>7} | {title}')
    print(f'       claude --resume {sid}')
    print()
"

if [ "$MODE" = "list" ]; then
    exit 0
fi

# --- Picker interactif ------------------------------------------------------
if [ "$MODE" = "picker" ]; then
    echo "Sélection : numéros séparés par des espaces, 'all' pour tout, 'q' pour quitter"
    read -r -p "> " selection
    [ -z "$selection" ] || [ "$selection" = "q" ] && { echo "Annulé."; exit 0; }
    if [ "$selection" = "all" ]; then
        INDICES=$(echo "$ACTIVE_JSON" | python3 -c "import json,sys; print(' '.join(str(i+1) for i in range(len(json.load(sys.stdin)))))")
    else
        INDICES="$selection"
    fi
elif [ "$MODE" = "auto" ]; then
    INDICES=$(echo "$ACTIVE_JSON" | python3 -c "import json,sys; print(' '.join(str(i+1) for i in range(len(json.load(sys.stdin)))))")
fi

# --- Exécute la restauration -----------------------------------------------
echo ""
echo "═══ Restauration ═══"
for idx in $INDICES; do
    JOB=$(echo "$ACTIVE_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); i=int('$idx')-1; s=d[i] if 0<=i<len(d) else None; print(json.dumps(s) if s else '')")
    [ -z "$JOB" ] && { echo "  ✗ index $idx invalide"; continue; }
    SID=$(echo "$JOB" | python3 -c "import json,sys; print(json.load(sys.stdin)['session_id'])")
    WS=$(echo "$JOB" | python3 -c "import json,sys; print(json.load(sys.stdin)['workspace_id'])")
    TITLE=$(echo "$JOB" | python3 -c "import json,sys; print(json.load(sys.stdin).get('title','?')[:40])")
    echo "  → WS:$WS ($TITLE)"
    "$CMUX_BIN" send --workspace "workspace:$WS" "claude-tracked --resume $SID" >/dev/null 2>&1
    "$CMUX_BIN" send-key --workspace "workspace:$WS" Enter >/dev/null 2>&1
    sleep 0.3
done
echo ""
echo "Restauration lancée. Switch dans cmux pour vérifier."
