# Auto-Update Visualization Pipeline

## Problem

You build D3.js visualizations of your film's characters, structure, emotions. Every time the bible changes, the visualizations are outdated. Manual regeneration = they never get updated.

## Solution

A three-stage pipeline: detect bible change → regenerate visu → deploy to Vercel. All automatic, triggered by Claude Code hooks.

## Architecture

```
Bible modified (Write/Edit tool on bible/ files)
    ↓ PostToolUse hook detects path match
regen-visu.py --all --deploy
    ↓
1. Read bible/personnages/ → extract characters → rebuild relationship map JSON
2. Read bible/structure-narrative/storyform.json → extract acts/sequences → rebuild emotion curve
3. Inject updated JSON into HTML files (regex replacement)
    ↓
visu-deploy.sh → Vercel --prod
    ↓
Live at https://your-project.vercel.app (unlisted, noindex)
```

## Hook configuration

Project-level `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "if echo \"$TOOL_INPUT\" | grep -qE 'visu/|bible/personnages|bible/structure-narrative|storyform'; then cd ~/Projects/Films/goldberg && python tools/regen-visu.py --all --deploy 2>/dev/null; fi",
            "timeout": 45,
            "async": true
          }
        ]
      }
    ]
  }
}
```

## Regeneration script

The Python script (`tools/regen-visu.py`) does:

1. **Character extraction**: Reads all `.md` files in `bible/personnages/`, detects type (FBI, JOURNALIST, FAMILY, etc.) from keywords, finds cross-references between characters, builds a graph.

2. **Structure extraction**: Reads `storyform.json` (NCP format), extracts acts and sequences with emotional values.

3. **HTML injection**: Uses regex to find and replace the embedded JSON data blocks (`const data = {...}` or `var acts = [...]`) in the HTML files.

4. **Deploy**: Copies HTML files to a temp directory, runs `npx vercel deploy --yes --prod`.

## Key decisions

- **Embedded data, not external JSON**: The HTML files are self-contained. Data is injected directly into `<script>` tags. This means any HTML file works offline, can be emailed, shared as attachment.
- **Regex replacement, not templating**: Simpler, no dependencies. The pattern `const data = {...};` is unique enough to match reliably.
- **Async hook**: The regeneration takes 5-10s. Running async means it doesn't block your editing flow.
- **Vercel unlisted**: `<meta name="robots" content="noindex, nofollow">` + no SEO = effectively unlisted. Anyone with the URL can see it, but it won't appear in search.
