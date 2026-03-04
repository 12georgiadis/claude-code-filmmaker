# Ghostty + cmux Workflow

Replaced iTerm2 in February 2026. Faster, simpler, zero AppleScript.

## Why the Switch

iTerm2 had two problems: custom layouts required AppleScript (fragile, slow), and split-pane navigation conflicted with Claude Code's `-CC` flag (broke all pane navigation). Ghostty + native tmux solved both.

## Ghostty

GPU-accelerated terminal. Key config (`~/.config/ghostty/config`):

```
font-family = JetBrains Mono
font-size = 13
theme = dark
window-decoration = false
```

The important part: Ghostty is just the glass. All layout intelligence lives in tmux.

## cmux — Native tmux Workflow

Instead of AppleScript or iTerm profiles, tmux handles everything:

```bash
# Launch a named project session
tmux new-session -s goldberg -n main
tmux split-window -h -t goldberg:main    # side panel
tmux split-window -v -t goldberg:main.1  # bottom panel

# Attach to existing
tmux attach -t goldberg

# Named windows per project
tmux new-window -t goldberg -n research
tmux new-window -t goldberg -n claude
```

Aliases in `~/.zshrc`:

```bash
alias za='tmux select-window -t :1'
alias zb='tmux select-window -t :2'
alias zc='tmux select-window -t :3'
alias zd='tmux select-window -t :4'
alias tls='tmux ls'
alias ta='tmux attach -t'
```

## Auto-Restore on Reboot

The resume-sessions script rebuilds all named tmux windows in order on startup. See [resume-sessions.md](resume-sessions.md) for implementation.

## Ghostty on Mac Mini (headless)

The Mac Mini doesn't run Ghostty (headless server). tmux sessions run directly in the SSH terminal, accessed from MacBook's Ghostty or iPad's Blink Shell. Same layout, different glass.

## Why Not tmux Plugin Managers

tmux-resurrect and similar plugins add complexity. The resume script (`~/.claude/scripts/ghostty-layout.sh`) is 30 lines and does exactly what's needed. Prefer explicit over magical.
