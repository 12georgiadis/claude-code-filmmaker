# Voice-Over Analysis Pipeline

A two-stage pipeline for analyzing audio recordings from documentary film production. Designed for filmmakers who record voice-over takes and director notes during shooting.

**Stack**: Local ASR (Parakeet v3 via MacWhisper) → Gemini Flash (semantic analysis) → Project codex update

---

## Problem

During documentary production, you accumulate:
- Voice-over takes (multiple attempts, varying quality)
- Director notes recorded between takes ("not sure about that line", "try flatter tone")
- Film references dropped casually ("think more Paranoid Park, less Marker")
- Corrections and delivery notes

This material is valuable but hard to process systematically. Scrubbing through 90+ audio clips manually takes hours. The goal: extract structured intelligence from raw recordings and feed it directly into the project's working documents.

---

## Architecture

```
SD card (audio recorder or camera)
    ↓ ingest.sh  [ffmpeg, audio extraction]
SESSION/audio/*.wav  (16kHz mono)
    ↓ MacWhisper GUI  [Parakeet v3, local, offline]
MacWhisper SQLite DB
    ↓ pipeline.py Phase A  [read DB]
SESSION/transcripts/*.json  (text + language + duration)
    ↓ pipeline.py Phase B  [Gemini Flash, async batches]
SESSION/analysis/*.json  (type, quality, refs, intonation)
    ↓ pipeline.py Phase C
SYNTHESIS.md + CODEX-UPDATES.md
    ↓ codex_update.py
Project bible updated  (references, VO selections, session log)
```

### Why two models?

| | Parakeet v3 | Gemini Flash |
|--|-------------|--------------|
| Role | Transcription | Semantic analysis |
| Speed | ~210x real-time | 5x real-time |
| Strengths | Precise timestamps, local, offline | Tone analysis, classification, ref extraction |
| Weaknesses | Text only, no context | Imprecise timestamps, cloud |
| Privacy | Total (no data sent) | Google API |

The split solves a real constraint: Parakeet is the best local ASR for French/English mixed audio and keeps raw footage private. Gemini handles the interpretation layer where sending processed text (not raw audio) is acceptable.

---

## Setup

### Dependencies

```bash
# ffmpeg for audio extraction
brew install ffmpeg

# Python packages
pip install google-genai

# MacWhisper (macOS app, requires Parakeet v3 model installed)
# https://goodsnooze.gumroad.com/l/macwhisper
```

### Environment

```bash
export GEMINI_API_KEY="your-key-here"
# Or store in a secrets file and load in the script
```

---

## Workflow

### 1. Ingest

Extract audio from all clips on the recording media:

```bash
./ingest.sh "2026-03-02-session" /Volumes/SD_CARD
```

Output: `production/vo-sessions/SESSION/audio/*.wav` (16kHz mono, one per clip)

The script skips already-extracted clips, so it's safe to run multiple times.

### 2. Transcribe (MacWhisper)

1. Open MacWhisper
2. Settings → **Watched Folders** → add the session's `audio/` folder
3. Select **Parakeet v3** as the model
4. Wait for MacWhisper to process all clips

Check progress:
```bash
python3 pipeline.py SESSION_NAME --check-mw
# Output: MacWhisper: 47/92 clips transcribed
```

### 3. Analyze + Synthesize

```bash
python3 pipeline.py SESSION_NAME
```

This:
- Reads all transcriptions from the MacWhisper SQLite DB
- Saves them as JSON (checkpoint — resumes safely if interrupted)
- Sends each transcript to Gemini Flash in batches of 5
- Generates `SYNTHESIS.md` (human-readable) and `CODEX-UPDATES.md` (machine-readable)

### 4. Update project documents

After reviewing `SYNTHESIS.md`:

```bash
# Dry run first
python3 codex_update.py SESSION_NAME --dry-run

# Apply
python3 codex_update.py SESSION_NAME
```

---

## Output Format

### Per-clip analysis (analysis/C0001.json)

```json
{
  "clip_id": "C0001",
  "type": "vo_take",
  "confidence": 0.94,
  "content_summary": "One sentence describing what was said or recorded",
  "vo_assessment": {
    "is_vo_take": true,
    "quality": "keeper",
    "reason": "Confident delivery, no hesitations, strong ending",
    "key_text": "The most significant line or phrase"
  },
  "director_notes": [],
  "film_references": [
    {
      "title": "Film title",
      "director": "Director name or null",
      "context": "Why this film was mentioned in this context"
    }
  ],
  "intonation": {
    "energy": "medium",
    "conviction": "high",
    "hesitation_level": "none",
    "tempo": "slow",
    "notable": "Long pause before final line, deliberate"
  },
  "codex_docs_to_update": ["references.md", "voix/"],
  "key_quotes": ["Verbatim quote worth keeping"],
  "goldberg_relevance": "high",
  "notes": null
}
```

### Session folder structure

```
production/vo-sessions/SESSION/
├── session.json           # session metadata
├── ingest.log             # audio extraction log
├── audio/                 # WAV files (16kHz mono)
├── transcripts/           # Parakeet v3 JSON per clip
├── analysis/              # Gemini analysis JSON per clip
├── SYNTHESIS.md           # human-readable synthesis
└── CODEX-UPDATES.md       # instructions for document updates
```

---

## Prompt Design

The Gemini prompt classifies each clip into one of:
- `vo_take` — a recorded narration attempt
- `director_comment` — filmmaker talking about the material
- `correction_note` — "redo this, try different tone"
- `film_reference` — reference to another film dropped in context
- `ambient_silence` — silence, room noise, unusable
- `mixed` — contains multiple types

The intonation assessment is the most subjective part and the most useful: it tells you not just *what* was said but *how* — energy, conviction, hesitation level. A technically correct VO take with low conviction scores differently than one with high conviction but a stumble.

---

## Checkpoint Architecture

Every expensive operation writes to disk immediately:
- Transcripts saved after MacWhisper reading
- Each Gemini analysis saved as it completes

If the script crashes at clip 45, restart with `--only-analyze` — it skips already-analyzed clips:

```bash
python3 pipeline.py SESSION_NAME --only-analyze
```

---

## Adaptation for Other Projects

The pipeline is general. To use it for a different project:

1. Change the codex update targets in `codex_update.py`
2. Adjust the Gemini prompt in `pipeline.py` (`ANALYSIS_USER`) to match your project's vocabulary
3. Change the `GOLDBERG_RELEVANCE` field to whatever relevance dimension matters for your project

The MacWhisper + faster-whisper combination works for any language. Parakeet v3 is particularly strong on English and handles French-English code-switching well.

---

## Files

| File | Purpose |
|------|---------|
| `ingest.sh` | SD card → WAV extraction via ffmpeg |
| `pipeline.py` | MacWhisper DB reading + Gemini analysis + synthesis |
| `codex_update.py` | Apply analysis results to project documents |
