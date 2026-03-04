# tmux Survival Guide

How to never lose a Claude Code session again.

## Setup

You need:
- A **server Mac** (always on, e.g. Mac Mini) running Claude Code inside tmux
- A **mobile device** (iPhone/iPad with [Blink Shell](https://blink.sh)) or another Mac
- [Tailscale](https://tailscale.com) on all devices for secure networking
- [mosh](https://mosh.org) on the server (`brew install mosh`)

## The golden rule

**Never launch `claude` without tmux.**

```bash
# ALWAYS
tmux new -s nom-du-projet
claude

# NEVER
claude   # naked, no safety net
```

## Connect from anywhere

### From iPhone/iPad (Blink + Tailscale)

```bash
# Connect to your server Mac
# --server flag required because Homebrew PATH is not in SSH env
mosh --server=/opt/homebrew/bin/mosh-server user@<tailscale-ip>

# Fallback if mosh doesn't work
ssh user@<tailscale-ip>

# Then reattach to your tmux session
tmux attach
```

### Between Macs

```bash
mosh user@<tailscale-ip>
tmux attach
```

### SSH vs Mosh?

- **Mosh**: auto-reconnects if Wi-Fi drops or iPad sleeps. Preferred.
- **SSH**: fallback if mosh doesn't work. Session dies if connection drops.
- Either way, tmux protects your running sessions.

## Daily workflow

```bash
# 1. On your server Mac, start a tmux session
tmux new -s work

# 2. Launch Claude Code inside
claude

# 3. Need another project? New tmux window
# Ctrl+B c = new window, Ctrl+B , = rename it

# 4. From phone: connect and reattach
# mosh --server=/opt/homebrew/bin/mosh-server user@<ip>
# tmux attach

# 5. Done for now? Detach (don't kill!)
# Ctrl+B d
```

## When things go wrong

### Closed iTerm / terminal (but Mac still running)

tmux survives! It runs in the background. Just reopen iTerm and:

```bash
tmux attach
```

### Battery dies / Mac reboots

tmux dies too. But Claude Code conversations are saved. Recovery:

```bash
# See all saved conversations
claude conversations list

# Resume any conversation inside tmux
tmux new -s work
claude --resume <conversation-id>
```

### Blink disconnects / iPhone locks

tmux survives. Just reconnect:

```bash
mosh --server=/opt/homebrew/bin/mosh-server user@<ip>
tmux attach
```

## Navigation cheatsheet

| Action | Keys |
|--------|------|
| **See all windows** | `Ctrl+B w` |
| Next window | `Ctrl+B n` |
| Previous window | `Ctrl+B p` |
| Go to window N | `Ctrl+B 0-9` |
| New window | `Ctrl+B c` |
| Rename window | `Ctrl+B ,` |
| **Detach** (leave without killing) | `Ctrl+B d` |
| Switch between sessions | `Ctrl+B s` |
| Split horizontal | `Ctrl+B "` |
| Split vertical | `Ctrl+B %` |
| Switch pane | `Ctrl+B arrow` |

On Blink keyboard: `Ctrl` = the `^` key (top left).

## Multiple projects

One tmux session with named windows works best:

```bash
tmux new -s work -n project-a
# Ctrl+B c  then  Ctrl+B ,  to add and rename windows
```

Or separate sessions for big contexts:

```bash
tmux new -s film
tmux new -s compta
tmux ls              # list all
Ctrl+B s             # switch between sessions
```

## Troubleshooting Blink (iPhone/iPad)

### Mouse/touch sends garbage characters (numbers, escape codes)

The touchscreen sends mouse events that tmux interprets as input. Fix:

```bash
# Add to ~/.tmux.conf on your server Mac:
echo 'set -g mouse off' >> ~/.tmux.conf

# Apply immediately without restart:
tmux set-option -g mouse off
```

Also: disable terminal escape sequences in the active session:
```bash
printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l'
```

### Vertical text / broken display

Terminal size mismatch between Blink and tmux. Fix:
1. `Ctrl+B d` (detach)
2. `tmux attach` (reattach resets dimensions)

### iTerm2 profile: do NOT use -CC flag

The `-CC` flag enables native iTerm2/tmux integration (tmux windows appear as iTerm2 tabs). Sounds useful, but it breaks everything:
- `Ctrl+B n/p` stop working for window navigation
- `Cmd+1/2/3` stop working
- Every new tab triggers an annoying popup

**Use this** in your iTerm2 profile command:
```
/opt/homebrew/bin/tmux attach -t your-session
```
**Not this:**
```
/opt/homebrew/bin/tmux -CC attach -t your-session
```

Note: inside Claude Code, `Cmd+←/→` are always captured for cursor movement — use `Ctrl+B n/p` instead.

### Can't type in Claude Code TUI

Keyboard not reaching the TUI. Fix:
1. `Ctrl+C` to exit Claude Code
2. Relaunch `claude` or `clauded`

### OAuth auth from iPad (no browser)

Claude Code auth requires a browser on the Mac. Options:
- Use a remote desktop app (AnyDesk, Jump Desktop, etc.) to control Safari on your server
- Copy credentials from another authenticated Mac:
  ```bash
  scp ~/.claude/.credentials.json user@<server-ip>:~/.claude/.credentials.json
  ```
- Auth stays valid as long as the session runs

### mosh: NoMoshServerArgs error

Homebrew's mosh-server is not in the default SSH PATH on macOS. Fix:
```bash
mosh --server=/opt/homebrew/bin/mosh-server user@host
```

### Enabling Screen Sharing (VNC) for remote desktop access

If you need GUI access to your server Mac (for OAuth, AnyDesk setup, etc.):
```bash
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -activate -configure -access -on -restart -agent -privs -all
```

Then connect via any VNC client or Jump Desktop using the Tailscale IP.

## Discipline

1. **Start of day**: `tmux new -s work` then `claude`
2. **During the day**: `Ctrl+B c` for new windows, `Ctrl+B ,` to name them
3. **End of day**: `Ctrl+B d` to detach (don't kill!)
4. **From phone**: `mosh` then `tmux attach`
5. **After reboot**: `claude --resume <id>` inside tmux
