# Agent Teams

Peer-to-peer multi-agent coordination. Agents share a task list, assign work to each other, and communicate directly — without the lead agent routing every message.

Enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `settings.json` (released with Opus 4).

## When to Use What

| Situation | Approach |
|-----------|----------|
| Single task or sequential work | Solo |
| 3-5 independent subtasks, no shared state | `Task` tool + classic subagents |
| Long coordination, dynamic task assignment, shared state between agents | Agent Teams |

The rule: Claude decides, not the user. Evaluate before every significant task.

## How It Works

1. **TeamCreate** — creates a team + shared task list
2. **TaskCreate/TaskList/TaskUpdate** — agents share and claim tasks
3. **SendMessage** — direct messaging between agents by name (never by UUID)
4. **SendMessage (shutdown_request)** — graceful shutdown when done
5. **TeamDelete** — cleanup after all agents shut down

## Core Patterns

### Spawning teammates

```
Task tool:
  subagent_type: "general-purpose"
  team_name: "my-team"
  name: "researcher"
  prompt: "Join team my-team. Check TaskList for your assignment."
```

### Task claiming

Agents check `TaskList`, pick the lowest-ID unblocked unowned task, claim it with `TaskUpdate (owner: "my-name")`, work, mark `completed`, repeat.

### Communication

```
SendMessage:
  type: "message"
  recipient: "researcher"   ← name, not UUID
  content: "Found the issue in auth module"
  summary: "Auth bug identified"
```

Broadcasts (`type: "broadcast"`) are expensive — N messages for N agents. Use sparingly: only for critical team-wide announcements.

### Shutdown sequence

Lead agent sends `shutdown_request` to each teammate. Teammate responds with `shutdown_response (approve: true)`. Lead calls `TeamDelete` after all confirmations.

## Identified Candidates for Agent Teams

From the backlog — tasks that warrant peer-to-peer over classic subagents:

- **`/council`** — debate between 32 persona agents, naturally peer-to-peer
- **Filmmaker AI Brain** — 4 independent components (text RAG, image, audio, video), one agent each
- **GEO Sprint 2** — 5 parallel SEO tasks with no dependencies

## Worktrees with Teams

When multiple agents touch the same git repo, activate `isolation: "worktree"` in the Task tool. Each agent works on an isolated copy, no merge conflicts. Available since Claude Code 2.1.50.

## What Not to Do

- Don't send JSON status blobs as messages (`{"type": "idle", ...}`). Use TaskUpdate for status, plain text for communication.
- Don't refer to teammates by UUID. Always use the name from the team config.
- Don't treat idle notifications as errors — agents go idle after every turn, they're just waiting.
