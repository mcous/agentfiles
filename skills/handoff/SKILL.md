---
name: handoff
description: >-
  Queue a work item for a later agent session, or pick up items queued for this one.
  Write when asked to "write a handoff", "leave a handoff", "hand this off", "queue this
  for", or "note this for" — addressed to another repo, to the
  repo you are in ("handoff to yourself", "leave a note for next session", "summarize
  your work in a handoff"), or to no repo at all (a ticket idea or stray follow-up for
  marvin). Fire even when the handoff is one clause of a larger request, and do it
  alongside the main task, not instead of it; a memory write is never a substitute for
  the file. Read when asked to check, process, or pick up handoffs, to process marvin's
  inbox, or what work is in flight across repos. Queue lives at
  ~/.config/agentfiles/handoffs/<target>/.
---

# Handoff

One machine-wide queue passes work between agent sessions:

```text
~/.config/agentfiles/handoffs/<target>/<YYYY-MM-DD>-<slug>.md
~/.config/agentfiles/handoffs/<target>/archive/   processed items
```

`<target>` is a repo's directory name (`agentfiles`, `my-app`), or `marvin` for
an item tied to no repo — a ticket idea, a follow-up to triage. The target repo need
not be cloned yet. Only directories are targets; files and dot-directories at the queue
root are not. Nothing reads the queue unprompted: no session-start check, no
aside in an unrelated answer.

## Write

1. Pick the target. Addressed to a repo means that repo, including the current one for
   a self-handoff; otherwise `marvin`. If unsure of a repo's exact directory name, ask —
   a typo creates a directory nothing reads.
2. Write one new file with the `Write` tool. Never append to or touch existing items.
3. Tell the user the filename and target, then return to the main task. Don't act on
   the item yourself, in another repo or this one.

```markdown
---
category: task
title: Short imperative title
source-repo: <repo you're writing from, if any>
source: <ticket, PR, or task you were working on>
created: YYYY-MM-DD
---

What the receiving agent needs to act without you: the change or idea, why,
file:line, links, and any ticket ID tying both sides together.
```

| Category | Use when |
|---|---|
| `task` | A concrete change for the target repo. The default for repo targets. |
| `context` | State, findings, or gotchas for the next session; no change requested. |
| `ticket` | An untracked idea that should become a ticket. The default for `marvin`. |

A ticket ID for already-tracked work goes in the body; the category says what the
receiver should do. If nothing fits, omit it.

## Pick up

Only when asked. Read `~/.config/agentfiles/handoffs/<target>/` for the current repo, or
`marvin` when running in the marvin workspace, oldest first, excluding `archive/`.

- `task` — make the change, following the repo's conventions.
- `context` — fold it into the current work; report what it changes.
- `ticket` — draft it following the `tickets` skill and confirm the draft before filing,
  unless the user has said to go ahead.
- Missing or unknown — surface it for manual triage.

After handling an item, move it to `archive/` and append a result line, e.g.
`_Processed YYYY-MM-DD → <link>_`. Never delete an item.

Asked what's in flight, list each target's top level, excluding `archive/`, and
report by target.
