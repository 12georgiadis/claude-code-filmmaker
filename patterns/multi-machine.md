# Multi-Machine Setup

Claude Code running across three machines with zero friction switching.

## The Setup

| Machine | Role | Access |
|---------|------|--------|
| MacBook Air M3 | Primary workstation (Paris + travel) | Local |
| Mac Mini M4 | Always-on headless server | SSH via Tailscale |
| PC Windows RTX 5090 | ComfyUI GPU inference | SSH via Tailscale |

**Network**: Tailscale mesh VPN connects everything. MacBook, Mac Mini, PC, iPhone, iPad all share a private network. SSH works from anywhere, including mobile data.

## Connecting to Mac Mini

```bash
# SSH (fast, for file ops)
ssh YOUR_MINI_USER@YOUR_MINI_TAILSCALE_IP

# mosh (stable, for interactive sessions on mobile/unstable networks)
mosh --server=/opt/homebrew/bin/mosh-server YOUR_MINI_USER@YOUR_MINI_TAILSCALE_IP
```

Once in: `tmux attach` — the Mac Mini always has a running tmux session named "claude".

## Sync Strategy

**MacBook = source of truth** for `~/.claude/`.

`~/.claude/` is a git repo synced to GitHub (private) every 30min on MacBook, 1h on Mini via cron. When branches diverge (both auto-syncing):

```bash
# On Mac Mini — reset to MacBook version
git fetch origin
git reset --hard origin/master
```

**Projects**: each project is a separate GitHub repo. Both machines clone from GitHub. Never sync directly between machines.

## SSH Key Setup

Each machine has its own `~/.ssh/id_ed25519` added to GitHub SSH keys. When setting up a new machine:

```bash
ssh-keygen -t ed25519 -C "machine-name@12georgiadis" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub
# Add to https://github.com/settings/ssh/new
```

## Git Identity (both machines)

```bash
git config --global user.name "Ismaël Joffroy Chandoutis"
git config --global user.email "13225628+12georgiadis@users.noreply.github.com"
```

## Remote Desktop (Mac Mini)

- **AnyDesk**: ID `YOUR_ANYDESK_ID` (LaunchAgent, auto-restart on reboot)
- **Jump Desktop**: IP `YOUR_MINI_TAILSCALE_IP` (VNC over Tailscale, iPad-friendly)
- **Parsec**: for low-latency gaming/creative use

## Mac Mini Permanence

The Mac Mini runs `caffeinate` and AnyDesk as LaunchAgents — it never sleeps and restarts services after reboot. Claude Code sessions persist in tmux. If a session dies, reconnect via SSH and `tmux new-session -s claude`.
