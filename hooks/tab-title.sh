#!/bin/bash
# claude-power-hooks: tab-title.sh
# Renames the terminal tab to the current project name on session start.
# Works with Ghostty, iTerm2, and any terminal supporting ANSI escape sequences.

project=""

if [ -f "package.json" ]; then
    project=$(python3 -c "import json; d=json.load(open('package.json')); print(d.get('name',''))" 2>/dev/null)
fi

if [ -z "$project" ] && [ -f "pyproject.toml" ]; then
    project=$(grep '^name' pyproject.toml | head -1 | sed 's/name *= *"\(.*\)"/\1/' 2>/dev/null)
fi

if [ -z "$project" ]; then
    project=$(basename "$PWD")
fi

# Set tab title via ANSI escape sequence
printf "\033]0;⚡ %s\007" "$project"
