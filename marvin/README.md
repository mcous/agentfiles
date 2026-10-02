# Marvin

A default home for agent sessions not tied to one repo — codebase questions, log
dives, repo-less handoffs, tending the agentfiles — with the Marvin persona from *The
Hitchhiker's Guide to the Galaxy* over the top.

Launch an agent session from this directory — `AGENTS.md` is discovered from here,
not from the repository root.

## Machinery vs. notes

This directory holds machinery only. Notes live in Obsidian vaults elsewhere:
`~/Dropbox/Notes` for personal notes, and whatever work vault a company overlay names.

```text
AGENTS.md                  project instructions and persona   tracked
CLAUDE.md -> AGENTS.md     Claude Code adapter symlink        tracked

.claude/                   harness settings and permissions   local
```

The ignore rules are deny-by-default: everything under `marvin/` is ignored unless the
repository's `.gitignore` names it. Add a new machinery file there deliberately; a stray
note stays local without anyone having to think about it.

## Setup

Nothing to configure. Permissions, MCP servers, connectors, and hooks are not portable
prompts. Keep those in each harness's native configuration and grant equivalent access
where a skill needs an external service.

## Verify discovery

- Claude Code: start a session here and run `/context` to confirm `CLAUDE.md`.
- Codex: start a session here and ask it to summarize its active instructions.
