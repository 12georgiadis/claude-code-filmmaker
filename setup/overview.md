# Claude Code Setup - Artist & Filmmaker Workflow

> How I use Claude Code as a filmmaker and contemporary artist working at the intersection of cinema, art, and AI.

This is a living document of my Claude Code configuration. Not a tutorial, not a template. A working setup that evolves daily.

## The Setup at a Glance

| Component | Count |
|---|---|
| Official plugins | 40+ (Notion, Vercel, Sentry, Figma, Playwright, HuggingFace...) |
| Custom skills | 109 |
| Agent personas | 38 (filmmakers, philosophers, artists) |
| Custom slash commands | 16 |
| Custom MCP servers | 3 (iMessage, Telegram, Postiz) |
| Custom scripts | 30+ (notifications, statusline, sync, heartbeat, backup) |
| Inter-session memory files | Growing daily |

## Architecture

```
~/.claude/
├── CLAUDE.md              # Master instructions (the brain)
├── BACKLOG.md             # Centralized project tracker
├── settings.json          # Hooks, statusline, permissions
├── agents/                # 38 creative consultant personas
├── skills/                # 109 skills (custom + plugin-managed)
├── scripts/               # Automation (notifications, sync, etc.)
├── memory/                # Inter-session persistence
├── sounds/                # Notification sounds
└── secrets/               # API keys (gitignored)
```

## Core Philosophy

Claude Code is not an assistant. It's a **collaborator that alters rather than augments**. It anticipates needs, produces proactively, analyzes patterns. No productivity coaching, no hustle, no sycophancy.

Key rules enforced in my config:
- **Anti-hallucination**: Never use simulated, invented, or approximate data
- **Scrap and redo**: When output is mediocre, restart from scratch with accumulated context rather than patching
- **Confrontation mode**: Challenge my choices when relevant. I'm not a dev, I need critical thinking, not passive execution
- **Self-updating rules**: After every significant error, the config updates itself to prevent repeats
- **One session = one subject**: No mixing accounting, SEO, and creative work in the same session

## Agent Personas

38 creative consultant personas spanning cinema, philosophy, art theory, and game design. Each persona has a distinct voice, methodology, and area of expertise.

They can be invoked individually for creative consultation or debated against each other via a `/council` command (in development).

The personas are private by design. The concept is public: a system that lets you think through creative decisions with the worldviews of artists and thinkers you admire.

## Skills (109)

Mix of custom-built and plugin-managed skills. Organized by domain:

### Creative Writing & Narrative (6)
`cw-brainstorming` `cw-prose-writing` `cw-story-critique` `cw-style-skill-creator` `cw-official-docs` `cw-router`

### Film & Creative Production
`pitch` (creative specs: films, games, installations, performances) `brainstorming` (mandatory before any creative work) `transcribe` `speech` `pdf` `doc`

### Image & Video Generation (12)
`fal-generate` `fal-image-edit` `fal-upscale` `fal-audio` `fal-workflow` `fal-platform` `imagegen` `sora` `nanobanana` `logo-creator` `banner-creator` `canvas-design` `image-manipulation-imagemagick` `video-downloader`

### 3D, Animation & Games (7)
`3d-web-experience` `develop-web-game` `game-development` `motion-canvas` `remotion` `remotion-best-practices` `algorithmic-art`

### Frontend & Web (8)
`frontend-design` `interactive-portfolio` `scroll-experience` `claude-d3js-skill` `excalidraw-diagram-generator` `web-artifacts-builder` `web-design-reviewer` `webapp-testing`

### SEO & Visibility (13)
`seo` `seo-audit` `seo-page` `seo-geo` `seo-competitor-pages` `seo-hreflang` `seo-images` `seo-sitemap` `seo-plan` `seo-schema` `seo-technical` `seo-content` `seo-programmatic`

### Research & Data (8)
`data-query` `reddit` `twitter` `x-research` `producthunt` `requesthunt` `domain-hunter` `agentic-eval`

### Development Workflow (17)
`dispatching-parallel-agents` `executing-plans` `finishing-a-development-branch` `gh-address-comments` `gh-fix-ci` `git-commit` `jupyter-notebook` `mermaid-diagrams` `playwright` `receiving-code-review` `requesting-code-review` `refactor` `skill-creator` `subagent-driven-development` `systematic-debugging` `verification-before-completion` `writing-plans`

### Security (3)
`security-best-practices` `security-ownership-map` `security-threat-model`

### Communication & Productivity (8)
`briefing` `inbox-sort` `linear` `notion-knowledge-capture` `notion-meeting-intelligence` `notion-research-documentation` `notion-spec-to-implementation` `prd`

### Deployment (5)
`cloudflare-deploy` `netlify-deploy` `render-deploy` `vercel-deploy` `yeet`

### Documentation & Files (6)
`pdf` `pdftk-server` `pptx` `spreadsheet` `screenshot` `mcp-builder`

### System & Tooling (8)
`status` `backup` `sync` `bootstrap` `cleanup` `skill-creator` `mcp-cli` `compta`

## Specs-Driven Development

I don't code directly. Every project follows this workflow:

```
1. /pitch [type]          → 15-25 creative questions
   (film, game, installation, performance, workshop)

2. Review & mature        → Adjust, let it sit

3. /interview [specs.md]  → 20-30 technical questions

4. Review specs           → Adjust implementation details

5. Plan Mode              → Claude proposes architecture

6. Implementation         → Code with full context
```

If I try to jump straight to code, Claude stops me and redirects to `/interview`.

## MCP Ecosystem

### Messaging (read & write across platforms)
- **iMessage** - Full history, search, contact enrichment, send
- **WhatsApp** - Chats, contacts, messages
- **Discord** - Servers, channels, forums, webhooks
- **Telegram** - Full account access (MTProto), group management, leave/join
- **Google Chat** - Spaces, threads, DMs

### Workspace
- **Gmail** - Search, read, send, labels, drafts
- **Google Calendar** - Events, free time, scheduling
- **Google Drive** - File search, download
- **Google Sheets/Slides/Docs** - Read, write, search
- **Notion** - Pages, databases, blocks, comments
- **Apple Notes** - Read, search

### Creative & Dev
- **Framer** - Direct site editing via MCP (project XML, node manipulation, CMS, code files, styles)
- **Chrome DevTools** - Screenshots, console, network, performance tracing
- **Obsidian** - Vault access, search, cache

### Research
- **Brave Search** - Web, news, images, video, local
- **Crypto Market** - Real-time data (Crypto.com Exchange)

## Notifications

Task completion triggers:
1. **Zelda treasure chest sound** (local `afplay`)
2. **Push notification** via Pushover (reaches iPhone/iPad instantly)

```bash
# ~/.claude/scripts/notify.sh
afplay ~/.claude/sounds/treasure.wav &
curl -s -F "token=${PUSHOVER_TOKEN}" -F "user=${PUSHOVER_USER}" \
  -F "message=${MESSAGE}" -F "title=Claude Code" \
  https://api.pushover.net/1/messages.json
```

Both `Stop` and `Notification` hooks are wired to this script.

## Status Line

A custom two-line status bar showing real-time session info:

```
[Opus] project-name │ main
████████░░░░ 67% │ $2.41 │ 34m ↻89% │ +124-38
```

Line 1: Model, project folder, git branch
Line 2: Context usage (color-coded progress bar), session cost, duration, cache hit rate, lines changed

The full script parses Claude Code's JSON status input with `jq` and formats it with ANSI colors.

## Remote Access (iPhone/iPad)

Full Claude Code access from mobile via tmux + Tailscale + mosh:

```
Mac (always-on)          iPhone/iPad
┌─────────────┐          ┌──────────────┐
│ tmux session │◄────────►│ mosh client  │
│  └─ claude   │  mosh    │ (Blink/a-Shell)
│              │  over    │              │
│  Tailscale   │  Tail-   │  Tailscale   │
│  100.x.x.x  │  scale   │  100.x.x.x  │
└─────────────┘          └──────────────┘
```

OAuth stays active as long as the tmux session lives. Detach/reattach seamlessly.

## Memory System

### Inter-session memory
Every significant session saves a summary to `~/.claude/memory/YYYY-MM-DD-subject.md`:
- Decisions made
- Problems solved (and how)
- Things learned
- TODOs for next session

### Centralized backlog
`~/.claude/BACKLOG.md` is the single source of truth for all active projects. Consulted at session start, updated at session end. Currently tracking 22 active workstreams and 14 completed.

### Memory search
```bash
mdfind -onlyin ~/.claude/memory/ "keyword"
```

## What's Different About This Setup

This isn't a developer's config. It's built for someone who:
- Makes **films** and **contemporary art**, not SaaS products
- Needs creative consultation, not code review
- Works across cinema, installation art, digital art, and games
- Treats AI as a collaborator in the artistic process, not a tool for productivity
- Manages complex multi-year film productions alongside daily comms and admin

The 38 agent personas aren't a gimmick. When I'm working on a documentary and need to think about the ethics of re-enactment, or when I'm designing an installation and need to consider the relationship between body and screen, having specialized creative perspectives available in the workflow changes the quality of the thinking.

## Hardware

- MacBook Air M3 (primary)
- Mac Mini (sync target)
- PC Windows (ComfyUI / GPU workloads via Tailscale)

## Stack

- **MacBook Air M3** — primary workstation (Ghostty + tmux, replaced iTerm2 Feb 2026)
- **Mac Mini M4** — headless server, always on (Paris), Claude Code 24/7
- **PC Windows RTX 5090** — ComfyUI GPU inference, accessible via Tailscale
- **iPhone/iPad** — Blink Shell + mosh for mobile Claude Code access
- **Ghostty** — GPU terminal, replaced iTerm2 (Feb 2026)
- **Postiz** — self-hosted social scheduling on Mac Mini (OrbStack/Docker)
- **Tailscale** — mesh VPN connecting all machines
- **Agent Teams** — peer-to-peer multi-agent coordination (experimental)

## Stats

- 40+ official plugins active
- 109 custom skills
- 38 agent personas
- 3 custom MCP servers + extensive plugin MCP ecosystem
- 5 messaging platforms accessible
- Multi-machine setup (MacBook + Mac Mini + PC Windows)
- Custom hooks, statusline, memory, remote access
- All running from the terminal, no IDE needed

---

**Ismaël Joffroy Chandoutis**
Filmmaker & Artist | Paris
[ismaeljoffroychandoutis.com](https://ismaeljoffroychandoutis.com)
