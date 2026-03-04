# Memory System

How to give Claude Code persistent memory across sessions.

## The problem

Each Claude Code session starts fresh. It doesn't remember what you did yesterday, what decisions you made, or what's on your backlog. You end up repeating context every time.

## The solution

Three layers of memory, from broad to specific:

### 1. CLAUDE.md (always loaded)

Your `~/.claude/CLAUDE.md` is loaded at the start of every session. It contains:
- Who you are and what you do
- Workflows and rules
- **Instructions to check the other memory layers**

The key line:
```markdown
## Inter-session memory
At the start of a session that continues an existing topic, search memory:
```bash
mdfind -onlyin ~/.claude/memory/ "keyword"
```
Or list recent files: `ls -lt ~/.claude/memory/ | head -20`
```

### 2. Daily memory logs (`~/.claude/memory/`)

At the end of every significant session, Claude Code saves a summary:

```
~/.claude/memory/
  2026-02-15-goldberg-database.md
  2026-02-16-seo-framer-setup.md
  2026-02-16-compta-videoformes.md
  2026-02-17-telegram-bridge-v3.md
```

Format:
```markdown
# [Topic] - [Date]
## Context
What we were working on and why.
## Decisions
Key choices made during the session.
## Resolved
Problems we fixed and how.
## Learned
New information or patterns discovered.
## TODO
What's left for the next session.
```

This is declared in CLAUDE.md so Claude Code does it automatically:
```markdown
### Auto-save
At the end of every significant session (not quick questions), save a summary
in `~/.claude/memory/YYYY-MM-DD-topic.md`
```

### 3. Backlog (`~/.claude/BACKLOG.md`)

A single file that tracks ALL active projects. Claude Code checks it at the start of sessions and updates it at the end.

```markdown
# Backlog

## In Progress
- [x] Telegram bridge v3 (voice + images)
- [ ] SEO audit on main site
- [ ] Film budget for Cannes submission

## On Hold
- [ ] Newsletter automation (waiting for Beehiiv API access)

## Done (recent)
- [x] Multi-machine tmux setup
- [x] Heartbeat agent v2
```

## How it works in practice

### Starting a session

Claude Code reads CLAUDE.md, sees the memory instructions, and:

1. Checks BACKLOG.md for context
2. If continuing a topic, searches memory:
   ```bash
   mdfind -onlyin ~/.claude/memory/ "telegram bridge"
   ```
3. Reads the relevant memory file
4. Has full context without you explaining anything

### Ending a session

Claude Code:
1. Saves a memory file with decisions, learnings, and TODOs
2. Updates BACKLOG.md (checks off done items, adds new ones)

### Searching memory

```bash
# By keyword (uses Spotlight, fast)
~/.claude/scripts/memory-search.sh "authentication"

# Recent files
~/.claude/scripts/memory-search.sh --recent 10

# Or directly
mdfind -onlyin ~/.claude/memory/ "keyword"
```

## The memory-search.sh script

```bash
#!/bin/bash
MEMORY_DIR="$HOME/.claude/memory"

if [ "$1" = "--recent" ]; then
    N="${2:-10}"
    ls -lt "$MEMORY_DIR" | head -$((N + 1))
elif [ -n "$1" ]; then
    # Spotlight (fast)
    mdfind -onlyin "$MEMORY_DIR" "$*" 2>/dev/null
    # Fallback to grep
    if [ $? -ne 0 ] || [ -z "$(mdfind -onlyin "$MEMORY_DIR" "$*" 2>/dev/null)" ]; then
        grep -rl "$*" "$MEMORY_DIR" 2>/dev/null
    fi
else
    echo "Usage: memory-search.sh [keyword]"
    echo "       memory-search.sh --recent [N]"
fi
```

## Design principles

1. **Claude Code writes its own memory.** You don't maintain it manually. The instructions in CLAUDE.md tell it to save and search.

2. **One file per session.** Not one giant file. Each session produces a focused, searchable document.

3. **Backlog is the index.** Memory files are the details, BACKLOG.md is the map of what's active.

4. **Spotlight for search.** On macOS, `mdfind` indexes files automatically. Instant full-text search across all memory files.

5. **Self-updating rules.** After every significant error or correction, Claude Code updates CLAUDE.md to prevent repeating the mistake. The instructions improve over time.
