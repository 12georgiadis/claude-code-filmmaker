# Context-Aware Suggestions Hook

## Problem

When you have 60+ skills, 30+ agents, 20+ MCP servers, and dozens of installed tools, you forget what's available. You end up asking for things manually, repeating the same requests, or missing tools that would solve your problem instantly.

## Solution

A `UserPromptSubmit` hook that reads your prompt, detects context keywords, and surfaces relevant tools/skills/agents before Claude even starts working.

## How it works

```
User types prompt
    ↓ UserPromptSubmit hook fires
context-suggestions.sh reads $CLAUDE_USER_PROMPT
    ↓ keyword matching
Suggestions appear as hook output
    ↓
Claude sees them and can use the suggested tools
```

## Architecture

The script is a simple bash file with grep-based keyword matching. Each context block checks for related keywords and appends suggestions.

### Context blocks

| Context | Keywords | Suggestions |
|---|---|---|
| Goldberg personas | `persona, character, personnage` | Pinecone RAG, /relationship-map |
| Goldberg structure | `scene, séquence, acte, structure` | storyform.json, auto-update visu |
| Video/Cinema | `vidéo, film, montage, cut` | LosslessCut, PySceneDetect, buttercut |
| Subtitles | `subtitle, sous-titre, srt` | /subtitle-workflow, MacWhisper |
| Festival | `festival, cannes, idfa` | /festival-submission, DCP-o-matic |
| Screenplay | `screenplay, scénario, coverage` | /script-coverage, scriptbook-analyzer |
| Photos | `photo, image, galerie` | osxphotos, Allusion |
| Obsidian | `obsidian, note, vault` | obsidian-skills, MCP |
| SEO | `seo, référencement` | Full SEO suite |
| Social | `twitter, tweet, social` | x-cli, crosspost, Postiz |
| Deploy | `deploy, héberger, vercel` | Vercel, cloudflared, deploy skills |
| Brainstorm | `brainstorm, idée, council` | /brainstorming, /council |
| Accounting | `compta, facture, urssaf` | /compta, Qonto MCP |

### Adding new contexts

```bash
# Add a new block to context-suggestions.sh
if echo "$PROMPT_LOWER" | grep -qE 'keyword1|keyword2'; then
  suggestions="$suggestions\n💡 Your suggestion here."
fi
```

## Settings integration

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/context-suggestions.sh",
            "timeout": 5,
            "async": true
          }
        ]
      }
    ]
  }
}
```

## Self-improving

The script should be updated whenever:
- A new tool is installed
- A new skill is created
- A workflow changes
- You notice yourself repeating the same request

The goal is zero repeated requests. If you ask for something twice, it should become a suggestion.
