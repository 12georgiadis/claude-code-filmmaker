# panes.jsonl — schema

Append-only JSONL. One line per event (not per session).

## Events

| event | when | required fields |
|-------|------|-----------------|
| `start` | claude-tracked launches claude | all |
| `heartbeat` | every 60s while claude is running | session_id, ts |
| `exit_clean` | claude quit cleanly (/quit or exit code 0) | session_id, ts |
| `exit_crash` | claude killed (signal or exit code != 0) | session_id, ts, exit_code |

## Fields

```json
{
  "event": "start",
  "ts": "2026-01-15T22:30:00Z",
  "session_id": "00000000-0000-0000-0000-000000000000",
  "workspace_id": "12",
  "surface_id": "34",
  "cwd": "/Users/<you>",
  "pid": 12345,
  "title": "<workspace title from cmux>",
  "args": "--dangerously-skip-permissions",
  "has_resume": false
}
```

```json
{"event":"heartbeat","ts":"2026-01-15T22:31:00Z","session_id":"00000000-..."}
```

```json
{"event":"exit_clean","ts":"2026-01-15T22:35:00Z","session_id":"00000000-...","exit_code":0}
```

## Reading rules

A session is **active** if:
- its last event is `start` or `heartbeat`
- AND `last_heartbeat` is recent (within `--max-age N` minutes, default 24h)
- AND no `exit_clean` / `exit_crash` event followed

`cmux-restore.sh` proposes to relaunch any session whose last event is not a clean exit and whose heartbeat is fresh enough.

## Rotation

`panes.jsonl` grows append-only. Manual or daily cron rotation:

```bash
mv ~/.claude/state/panes.jsonl ~/.claude/state/panes-$(date +%Y%m%d).jsonl
touch ~/.claude/state/panes.jsonl
```
