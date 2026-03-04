# Cross-Platform Compatibility

All scripts work on macOS, Linux, and Windows (WSL2). Here's how.

## Architecture

```
Your script
    |
    source platform.sh
    |
    ├── play_sound()         → afplay / paplay / PowerShell
    ├── send_notification()  → osascript / notify-send / PowerShell toast
    ├── prevent_sleep()      → caffeinate / systemd-inhibit / PowerShell
    ├── search_files()       → mdfind (Spotlight) / grep -r
    ├── schedule_task()      → LaunchAgent / cron
    ├── pkg_install()        → brew / apt / dnf / pacman
    └── open_url()           → open / xdg-open / cmd.exe start
```

Every script sources `platform.sh` at the top. Platform detection is automatic.

## platform.sh

The abstraction layer that makes everything work. Source it in any script:

```bash
#!/bin/bash
source ~/.claude/scripts/platform.sh

# Now use cross-platform functions:
play_sound ~/.claude/sounds/treasure.wav
send_notification "Claude Code" "Build complete"
```

### Platform detection

```bash
detect_platform  # called automatically on source
echo $PLATFORM   # "macos", "linux", or "wsl"
```

WSL is detected by checking `/proc/version` for "microsoft".

### Available functions

| Function | macOS | Linux | WSL2 |
|----------|-------|-------|------|
| `play_sound file` | afplay | paplay/aplay/mpv | PowerShell SoundPlayer |
| `send_notification title msg` | osascript | notify-send | PowerShell toast |
| `prevent_sleep` | caffeinate | systemd-inhibit | PowerShell loop |
| `allow_sleep` | kill caffeinate | kill inhibit | kill loop |
| `search_files dir query` | mdfind (Spotlight) | grep -r | grep -r |
| `schedule_task name min script` | LaunchAgent | cron | cron |
| `remove_task name` | unload LaunchAgent | remove cron | remove cron |
| `pkg_install pkg` | brew | apt/dnf/pacman | apt/dnf/pacman |
| `open_url url` | open | xdg-open | cmd.exe /c start |

## WSL2 specifics

WSL2 is the recommended way to run on Windows. Key points:

- **Network**: WSL2 shares the Windows network stack. Tailscale installed on Windows works for WSL.
- **Sound**: Uses `powershell.exe` to play sounds through Windows audio. No Linux audio stack needed.
- **Notifications**: Windows toast notifications via PowerShell. They show up in Windows notification center.
- **tmux**: Works natively in WSL2. Same as Linux.
- **mosh**: Works natively in WSL2. Same as Linux.
- **File access**: WSL can read/write Windows files via `/mnt/c/`. Windows can access WSL files via `\\wsl$\`.
- **Sleep prevention**: Less relevant since Windows manages sleep independently of WSL.

### WSL2 setup checklist

1. Install WSL2: `wsl --install` (PowerShell admin)
2. Install Ubuntu (default) or your preferred distro
3. Install Tailscale on **Windows** (not in WSL)
4. Run `bootstrap.sh` inside WSL
5. `tmux new -s claude && claude`

## Bootstrap

The `bootstrap.sh` script handles all platform differences:

```bash
# On any machine (macOS, Linux, WSL2):
bash ~/.claude/scripts/bootstrap.sh
```

It will:
1. Detect your OS and package manager
2. Install Node.js, tmux, mosh, jq, git
3. On Linux: install notify-send and audio tools
4. On WSL: skip Linux-specific tools, note Windows equivalents
5. Clone config, set up aliases, cron, tmux.conf
6. Print platform-specific next steps

## Adding new platform-specific code

If you need a new platform-dependent feature:

1. Add the function to `platform.sh` with a case statement
2. Test on all platforms (or at least macOS + one other)
3. Use the function in your script via `source platform.sh`

```bash
# In platform.sh:
my_new_function() {
    case "$PLATFORM" in
        macos) ... ;;
        wsl) ... ;;
        linux) ... ;;
    esac
}

# In your script:
source ~/.claude/scripts/platform.sh
my_new_function
```
