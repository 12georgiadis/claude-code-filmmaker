# Statusline

A two-line status bar for Claude Code that shows model, project, context usage, cost, duration, cache hit rate, and lines changed.

## What it looks like

```
[Opus] my-project | main
████████████░░░░ 75% | $1.23 | 45m | ↻82% | +150-30
```

Line 1: model, folder name, git branch
Line 2: context window progress bar (color-coded), session cost, duration, cache %, lines added/removed

## Why

The default Claude Code UI doesn't show how much of the context window you've used. This is critical information: when you're at 80%+, responses degrade and you should start a new session. The progress bar turns green/yellow/red accordingly.

The cost counter helps track API-equivalent spending. Cache % tells you how efficiently the conversation is being cached.

## Setup

In `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/statusline.sh"
  }
}
```

## The script

The statusline receives JSON on stdin with session data. It extracts values via `jq` and formats them.

```bash
#!/bin/bash
stdin_data=$(cat)

# Extract all values in one jq call
IFS=$'\t' read -r current_dir model_name cost lines_added lines_removed \
  duration_ms ctx_used cache_pct < <(
  echo "$stdin_data" | jq -r '[
    .workspace.current_dir // .cwd // "unknown",
    .model.display_name // "Unknown",
    (try (.cost.total_cost_usd // 0 | . * 100 | floor / 100) catch 0),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.cost.total_duration_ms // 0),
    (try (
      if (.context_window.used_percentage // null) != null then
        .context_window.used_percentage | floor
      elif (.context_window.remaining_percentage // null) != null then
        100 - (.context_window.remaining_percentage | floor)
      elif (.context_window.context_window_size // 0) > 0 then
        (((.context_window.current_usage.input_tokens // 0) +
          (.context_window.current_usage.cache_creation_input_tokens // 0) +
          (.context_window.current_usage.cache_read_input_tokens // 0)) * 100 /
          .context_window.context_window_size) | floor
      else "null" end
    ) catch "null"),
    (try (
      (.context_window.current_usage // {}) |
      if (.input_tokens // 0) + (.cache_read_input_tokens // 0) > 0 then
        ((.cache_read_input_tokens // 0) * 100 /
        ((.input_tokens // 0) + (.cache_read_input_tokens // 0))) | floor
      else 0 end
    ) catch 0)
  ] | @tsv'
)

# Git info
if cd "$current_dir" 2>/dev/null; then
  git_branch=$(git branch --show-current 2>/dev/null)
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
fi
folder_name=$(basename "${git_root:-$current_dir}")

# Progress bar (color-coded: green < 50%, yellow < 80%, red >= 80%)
bar_width=12
if [ -n "$ctx_used" ] && [ "$ctx_used" != "null" ]; then
  filled=$((ctx_used * bar_width / 100))
  empty=$((bar_width - filled))
  if [ "$ctx_used" -lt 50 ]; then
    bar_color='\033[32m'    # green
  elif [ "$ctx_used" -lt 80 ]; then
    bar_color='\033[33m'    # yellow
  else
    bar_color='\033[31m'    # red
  fi
  progress_bar="${bar_color}"
  for ((i=0; i<filled; i++)); do progress_bar+="█"; done
  progress_bar+="\033[2m"
  for ((i=0; i<empty; i++)); do progress_bar+="░"; done
  progress_bar+="\033[0m"
fi

# Duration formatting
if [ "$duration_ms" -gt 0 ] 2>/dev/null; then
  total_sec=$((duration_ms / 1000))
  hours=$((total_sec / 3600))
  minutes=$(((total_sec % 3600) / 60))
  if [ "$hours" -gt 0 ]; then
    session_time="${hours}h${minutes}m"
  elif [ "$minutes" -gt 0 ]; then
    session_time="${minutes}m"
  else
    session_time="${total_sec}s"
  fi
fi

# Short model name (strip "Claude X.X" prefix)
short_model=$(echo "$model_name" | sed -E 's/Claude [0-9.]+ //; s/^Claude //')

SEP='\033[2m|\033[0m'

# Line 1: [Model] folder | branch
line1=$(printf '\033[37m[%s]\033[0m \033[94m%s\033[0m' "$short_model" "$folder_name")
[ -n "$git_branch" ] && line1+=" $(printf '%b \033[96m%s\033[0m' "$SEP" "$git_branch")"

# Line 2: progress bar context% | $cost | duration | cache% | lines
line2=$(printf '%b \033[37m%s\033[0m' "$progress_bar" "${ctx_used}%")
line2+=" $(printf '%b \033[33m$%s\033[0m' "$SEP" "$cost")"
[ -n "$session_time" ] && line2+=" $(printf '%b \033[36m%s\033[0m' "$SEP" "$session_time")"
[ "$cache_pct" -gt 0 ] 2>/dev/null && line2+=" $(printf ' \033[2m↻%s%%\033[0m' "$cache_pct")"
if [ "$lines_added" -gt 0 ] 2>/dev/null || [ "$lines_removed" -gt 0 ] 2>/dev/null; then
  line2+=" $(printf '%b \033[32m+%s\033[0m\033[31m-%s\033[0m' "$SEP" "$lines_added" "$lines_removed")"
fi

printf '%b\n\n%b' "$line1" "$line2"
```

## Requirements

- `jq` installed (`brew install jq`)
- Claude Code with statusLine support (check your version)

## Credits

Inspired by [@__BOMO](https://x.com/__BOMO)'s context window statusline concept.
