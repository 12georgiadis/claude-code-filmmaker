#!/bin/bash
# Platform abstraction layer for Claude Code scripts
# Source this at the top of any script that uses OS-specific features:
#   source ~/.claude/scripts/platform.sh

# --- Platform detection ---
detect_platform() {
    case "$(uname -s)" in
        Darwin) PLATFORM="macos" ;;
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                PLATFORM="wsl"
            else
                PLATFORM="linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
        *) PLATFORM="unknown" ;;
    esac
    export PLATFORM
}

detect_platform

# --- Sound playback ---
# Usage: play_sound /path/to/sound.wav
play_sound() {
    local file="$1"
    [ ! -f "$file" ] && return 1
    case "$PLATFORM" in
        macos)
            afplay "$file" 2>/dev/null &
            ;;
        wsl)
            # Use Windows media player via PowerShell
            local win_path
            win_path=$(wslpath -w "$file" 2>/dev/null || echo "$file")
            powershell.exe -NoProfile -Command \
                "(New-Object Media.SoundPlayer '$win_path').PlaySync()" 2>/dev/null &
            ;;
        linux)
            if command -v paplay &>/dev/null; then
                paplay "$file" 2>/dev/null &
            elif command -v aplay &>/dev/null; then
                aplay "$file" 2>/dev/null &
            elif command -v mpv &>/dev/null; then
                mpv --no-video "$file" 2>/dev/null &
            fi
            ;;
    esac
}

# --- System notifications ---
# Usage: send_notification "Title" "Message body"
send_notification() {
    local title="${1:-Claude Code}"
    local message="${2:-Task done}"
    case "$PLATFORM" in
        macos)
            osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\"" 2>/dev/null
            ;;
        wsl)
            # Windows toast notification via PowerShell
            powershell.exe -NoProfile -Command "
                [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null
                \$xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
                \$xml.LoadXml('<toast><visual><binding template=\"ToastText02\"><text id=\"1\">$title</text><text id=\"2\">$message</text></binding></visual></toast>')
                [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$xml)
            " 2>/dev/null || \
            # Fallback: simple PowerShell notification
            powershell.exe -NoProfile -Command \
                "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$message','$title')" 2>/dev/null &
            ;;
        linux)
            if command -v notify-send &>/dev/null; then
                notify-send "$title" "$message" 2>/dev/null
            fi
            ;;
    esac
}

# --- Prevent sleep ---
# Usage: prevent_sleep
# Writes PID to ~/.claude/nosleep.pid
prevent_sleep() {
    local pidfile=~/.claude/nosleep.pid
    if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        echo "Already active (PID $(cat "$pidfile"))"
        return 0
    fi
    case "$PLATFORM" in
        macos)
            caffeinate -dims &
            echo $! > "$pidfile"
            ;;
        wsl)
            # WSL: Windows manages sleep, but we can use powershell to prevent it
            powershell.exe -NoProfile -Command \
                "while(\$true){[System.Threading.Thread]::Sleep(60000)}" &
            echo $! > "$pidfile"
            ;;
        linux)
            if command -v systemd-inhibit &>/dev/null; then
                systemd-inhibit --what=idle --who="Claude Code" --why="Long running task" \
                    sleep infinity &
                echo $! > "$pidfile"
            elif command -v xdg-screensaver &>/dev/null; then
                xdg-screensaver suspend "$$" 2>/dev/null
                echo $$ > "$pidfile"
            else
                # Fallback: keep-alive loop
                while true; do sleep 300; done &
                echo $! > "$pidfile"
            fi
            ;;
    esac
    echo "NoSleep active (PID $(cat "$pidfile"))"
}

# --- Allow sleep ---
# Usage: allow_sleep
allow_sleep() {
    local pidfile=~/.claude/nosleep.pid
    if [ -f "$pidfile" ]; then
        kill "$(cat "$pidfile")" 2>/dev/null
        rm -f "$pidfile"
        echo "NoSleep disabled."
    else
        echo "NoSleep was not active."
    fi
}

# --- Full-text search in directory ---
# Usage: search_files /path/to/dir "query"
search_files() {
    local dir="$1"
    local query="$2"
    case "$PLATFORM" in
        macos)
            # Spotlight (fast, indexed)
            local results
            results=$(mdfind -onlyin "$dir" "$query" 2>/dev/null)
            if [ -n "$results" ]; then
                echo "$results"
            else
                # Fallback to grep
                grep -rl "$query" "$dir" 2>/dev/null
            fi
            ;;
        linux|wsl)
            # grep (always works)
            grep -rl "$query" "$dir" 2>/dev/null
            ;;
    esac
}

# --- Schedule a recurring task ---
# Usage: schedule_task "name" "interval_minutes" "/path/to/script.sh"
schedule_task() {
    local name="$1"
    local interval="$2"
    local script="$3"
    case "$PLATFORM" in
        macos)
            local plist="$HOME/Library/LaunchAgents/com.claude.$name.plist"
            local interval_sec=$((interval * 60))
            cat > "$plist" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.$name</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$script</string>
    </array>
    <key>StartInterval</key>
    <integer>$interval_sec</integer>
    <key>StandardOutPath</key>
    <string>$HOME/.claude/logs/$name.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.claude/logs/$name.err</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>$HOME</string>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.nvm/versions/node/v22.22.0/bin:$HOME/.local/bin</string>
    </dict>
</dict>
</plist>
PLISTEOF
            launchctl load "$plist" 2>/dev/null
            echo "Scheduled $name every ${interval}min (LaunchAgent)"
            ;;
        linux|wsl)
            # cron
            local cron_expr="*/$interval * * * *"
            (crontab -l 2>/dev/null | grep -v "$name"; \
             echo "$cron_expr /bin/bash $script >> $HOME/.claude/logs/$name.log 2>&1 # $name") | crontab -
            echo "Scheduled $name every ${interval}min (cron)"
            ;;
    esac
}

# --- Remove a scheduled task ---
# Usage: remove_task "name"
remove_task() {
    local name="$1"
    case "$PLATFORM" in
        macos)
            local plist="$HOME/Library/LaunchAgents/com.claude.$name.plist"
            launchctl unload "$plist" 2>/dev/null
            rm -f "$plist"
            echo "Removed $name (LaunchAgent)"
            ;;
        linux|wsl)
            crontab -l 2>/dev/null | grep -v "$name" | crontab -
            echo "Removed $name (cron)"
            ;;
    esac
}

# --- Package manager ---
# Usage: pkg_install package_name
pkg_install() {
    local pkg="$1"
    case "$PLATFORM" in
        macos)
            if command -v brew &>/dev/null; then
                brew install "$pkg"
            else
                echo "Install Homebrew first: https://brew.sh"
                return 1
            fi
            ;;
        linux|wsl)
            if command -v apt &>/dev/null; then
                sudo apt install -y "$pkg"
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y "$pkg"
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm "$pkg"
            else
                echo "No supported package manager found"
                return 1
            fi
            ;;
    esac
}

# --- Open URL in browser ---
# Usage: open_url "https://example.com"
open_url() {
    local url="$1"
    case "$PLATFORM" in
        macos) open "$url" ;;
        wsl) cmd.exe /c start "$url" 2>/dev/null || powershell.exe -Command "Start-Process '$url'" ;;
        linux) xdg-open "$url" 2>/dev/null || sensible-browser "$url" 2>/dev/null ;;
    esac
}
