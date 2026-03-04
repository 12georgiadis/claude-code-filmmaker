# Telegram Bridge

Control Claude Code from your phone via a Telegram bot. Bidirectional: send messages, voice notes, images, and files from Telegram, get responses back.

## How it works

```
iPhone/iPad (Telegram)
    |
    v
Telegram Bot API (polling)
    |
    v
telegram-bridge.py (running on your Mac)
    |
    v
tmux send-keys → Claude Code session
    |
    v
tmux capture-pane → extract response
    |
    v
Telegram Bot API → send response back
```

The bridge runs as a background process on your Mac. It polls the Telegram Bot API, receives messages, and injects them into a tmux pane where Claude Code is running. It then captures the output and sends it back.

## Features

- **Text messages**: sent directly to Claude Code
- **Voice notes**: downloaded, transcribed locally via whisper-cpp, then sent as text
- **Images**: downloaded, saved locally, path sent to Claude Code with caption
- **Files**: downloaded, saved locally, path sent to Claude Code for analysis
- **Multi-window**: switch between tmux windows with `/0`, `/1`, `/2`...
- **Screen capture**: see what's on screen with `/screen`
- **Dashboard**: system overview with `/dashboard`

## Commands

| Command | Action |
|---------|--------|
| `/screen` | Capture current tmux pane output |
| `/status` | Show bridge status, session info, whisper availability |
| `/dashboard` | Run the dashboard script (sessions, costs, agents) |
| `/list` | List all tmux windows |
| `/0` `/1` `/2`... | Switch to tmux window N |
| `/stop` | Stop the bridge |
| Any text | Send to Claude Code and wait for response |

## Setup

### 1. Create a Telegram bot

Talk to [@BotFather](https://t.me/BotFather) on Telegram:
1. `/newbot`
2. Choose a name (e.g., "My Claude Bridge")
3. Save the token

### 2. Get your chat ID

Send a message to your bot, then:
```bash
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates"
```
Look for `"chat":{"id":123456789}` in the response.

### 3. Create secrets file

```bash
mkdir -p ~/.claude/secrets
cat > ~/.claude/secrets/telegram.env << 'EOF'
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here
EOF
```

### 4. Install dependencies

```bash
# For voice transcription (optional)
brew install ffmpeg
# Build whisper-cpp or install whisper-cli
# Download a model: ggml-base.bin
mkdir -p ~/.claude/models
# Place ggml-base.bin in ~/.claude/models/
```

### 5. The bridge script

```python
#!/usr/bin/env python3
"""Telegram <> Claude Code bridge.
Bidirectional + multi-session + voice + images/files.
"""
import os, sys, time, json, subprocess
import urllib.request, urllib.parse, signal, tempfile

# Load config from env file
def load_env():
    env = {}
    with open(os.path.expanduser("~/.claude/secrets/telegram.env")) as f:
        for line in f:
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                env[k] = v
    return env

config = load_env()
TOKEN = config["TELEGRAM_BOT_TOKEN"]
CHAT_ID = config["TELEGRAM_CHAT_ID"]
API = f"https://api.telegram.org/bot{TOKEN}"
POLL_INTERVAL = 2
PIDFILE = os.path.expanduser("~/.claude/telegram-bridge.pid")
MEDIA_DIR = os.path.expanduser("~/.claude/telegram-media")
WHISPER_MODEL = os.path.expanduser("~/.claude/models/ggml-base.bin")

os.makedirs(MEDIA_DIR, exist_ok=True)
current_window = "0"

def telegram_get(method, params=None):
    url = f"{API}/{method}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            return json.loads(resp.read())
    except Exception as e:
        return {"ok": False, "error": str(e)}

def telegram_send(text):
    if len(text) > 4000:
        text = text[-4000:]
    data = urllib.parse.urlencode({
        "chat_id": CHAT_ID, "text": text, "parse_mode": "Markdown"
    }).encode()
    try:
        req = urllib.request.Request(f"{API}/sendMessage", data=data)
        urllib.request.urlopen(req, timeout=10)
    except Exception:
        # Retry without markdown (in case of formatting issues)
        try:
            data = urllib.parse.urlencode({"chat_id": CHAT_ID, "text": text}).encode()
            req = urllib.request.Request(f"{API}/sendMessage", data=data)
            urllib.request.urlopen(req, timeout=10)
        except Exception:
            pass

def download_telegram_file(file_id, dest_path):
    try:
        result = telegram_get("getFile", {"file_id": file_id})
        if not result.get("ok"):
            return False
        file_path = result["result"]["file_path"]
        url = f"https://api.telegram.org/file/bot{TOKEN}/{file_path}"
        urllib.request.urlretrieve(url, dest_path)
        return True
    except Exception:
        return False

def transcribe_audio(audio_path):
    """Transcribe audio using whisper-cpp (local, offline)."""
    try:
        wav_path = audio_path + ".wav"
        subprocess.run(
            ["ffmpeg", "-y", "-i", audio_path, "-ar", "16000", "-ac", "1",
             "-c:a", "pcm_s16le", wav_path],
            capture_output=True, timeout=30
        )
        result = subprocess.run(
            ["whisper-cli", "-m", WHISPER_MODEL, "-l", "auto",
             "--no-timestamps", "-f", wav_path],
            capture_output=True, text=True, timeout=60
        )
        os.remove(wav_path)
        os.remove(audio_path)
        lines = [l.strip() for l in result.stdout.split("\n")
                 if l.strip() and not l.startswith("whisper_")]
        return " ".join(lines) if lines else None
    except Exception:
        return None

def get_tmux_session():
    try:
        result = subprocess.run(
            ["tmux", "list-sessions", "-F", "#{session_name}"],
            capture_output=True, text=True, timeout=5
        )
        sessions = result.stdout.strip().split("\n")
        for s in sessions:
            if s and "claude" in s.lower():
                return s
        return sessions[0] if sessions and sessions[0] else None
    except Exception:
        return None

def send_to_tmux(pane, text):
    try:
        subprocess.run(["tmux", "send-keys", "-t", pane, "C-u"], timeout=5)
        time.sleep(0.1)
        subprocess.run(["tmux", "send-keys", "-t", pane, "-l", text], timeout=5)
        time.sleep(0.5)
        subprocess.run(["tmux", "send-keys", "-t", pane, "C-m"], timeout=5)
        return True
    except Exception:
        return False

def get_tmux_output(pane, lines=50):
    try:
        result = subprocess.run(
            ["tmux", "capture-pane", "-t", pane, "-p", "-S", f"-{lines}"],
            capture_output=True, text=True, timeout=5
        )
        return result.stdout.strip()
    except Exception:
        return None

def wait_for_response(pane, before_output, timeout=120):
    """Wait until Claude Code output stabilizes."""
    start = time.time()
    last_output = before_output
    stable_count = 0
    time.sleep(3)
    while time.time() - start < timeout:
        current = get_tmux_output(pane, 60)
        if current and current != last_output:
            last_output = current
            stable_count = 0
        else:
            stable_count += 1
        if stable_count >= 2 and current != before_output:
            return current
        time.sleep(2)
    return last_output

# Main loop: poll Telegram, dispatch to handlers, send to tmux
# See full implementation in the repo
```

### 6. Start/stop scripts

**Start:**
```bash
#!/bin/bash
PIDFILE=~/.claude/telegram-bridge.pid

if [ -f "$PIDFILE" ] && kill -0 "$(cat $PIDFILE)" 2>/dev/null; then
    echo "Bridge already running (PID $(cat $PIDFILE))"
    exit 0
fi

nohup python3 ~/.claude/scripts/telegram-bridge.py \
    > ~/.claude/logs/telegram-bridge.log 2>&1 &
echo "Telegram bridge started (PID $!)"
```

**Stop:**
```bash
#!/bin/bash
PIDFILE=~/.claude/telegram-bridge.pid
[ -f "$PIDFILE" ] && kill "$(cat $PIDFILE)" 2>/dev/null
rm -f "$PIDFILE"
echo "Bridge stopped."
```

## Why this matters

When Claude Code is running a long task (building, searching, processing), you can walk away from your desk and monitor/interact from your phone. No SSH client needed, no terminal app, just Telegram.

Combined with tmux + Tailscale, you get full remote control of Claude Code from anywhere.

## Limitations

- Voice transcription requires whisper-cpp installed locally
- Response extraction from tmux is heuristic-based (parses screen output)
- Long responses may be truncated (Telegram 4096 char limit)
- No delivery confirmation for messages sent to Claude Code
- The bridge must run on the same machine as tmux/Claude Code
