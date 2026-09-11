---
name: tickets
description: >
  Writing and filing tickets, specs, and issues, including in Linear. Use whenever a
  ticket is about to be drafted or filed, however phrased ("write a ticket", "log this",
  "track this", "have them file a ticket") — including tickets that only record known
  work or debt, and including when the filing is delegated to a subagent. Covers
  structure, principles, and filing rules. Invoked with /tickets.
user-invocable: true
---

# Writing Tickets

## Structure

Every ticket has 2–3 sections in this order:

1. **Overview** (required) — ~80 words
2. **Acceptance Criteria** (required) — no word budget; more than ~7 items means
   the ticket is too big, so split it
3. **Implementation Notes** (optional) — ~80 words

Budgets are per section, not pooled — a long Implementation Notes doesn't buy a
compressed Overview.

Title: short plain-English headline. No "Ticket:" prefix, no bold decorators.

---

## Sections

### Overview

Brief description of the goal. Include a user story ("As a user, I'd like to...") when delivering user-facing value. High-level — don't prescribe implementation.

### Acceptance Criteria

Bulleted list of conditions that must be true to close the ticket. Each item concrete and verifiable. Where uncertainty exists, include a timeboxed investigation item rather than leaving it open-ended.

### Implementation Notes

Only include when there are hard technical constraints, known gotchas, or scaffolding decisions that shouldn't be left to the engineer. Don't prescribe approach when the engineer can decide for themselves.

---

## Principles

**Write top-down, not bottom-up.** Scope around observable outcomes, not internal building blocks. If an engineer can't describe how they'd test the AC end-to-end, the ticket is at the wrong level.

**Find the right granularity.** Small enough to hold in your head; large enough to deliver something observable and testable. Two large tickets is as bad as eight small ones. Check: could an engineer accidentally build the wrong thing by picking up this ticket before another?

**Leave implementation to the engineer** unless the task is extremely specific.

**Point to prior art.** Reference existing code, notebooks, or scripts that define expected behavior rather than re-specifying working code.

**Prefer clarity over completeness.** A short, clear ticket beats a long, exhaustive one.

**Flags, rollout, dependencies → Implementation Notes** when relevant.

**Tickets and comments carry the LLM-attribution footer** — see CLAUDE.md. Include it in drafts shown for approval, so what Michael approves is what gets posted.

---

## Filing

Load the tracker's own skill, if one is installed (e.g. `linear`), for the team, IDs, and
handles.

Preflight, every time:

- Overview and Acceptance Criteria present
- Status set to Triage
- Priority left unset
- Team is my primary team, or one Michael has explicitly approved
- LLM-attribution footer included
- Searched for an existing ticket, archived and completed included — report a match
  instead of filing a duplicate

**Triage status, no priority, unless Michael says otherwise.** Never Backlog by
default, never guess a priority, and never move a ticket out of a team's Triage
intake on your own initiative.

**Filing outside my primary team needs explicit approval.** Show the draft, name the target
team, wait for a yes. Don't file and ask after.

**Delegating doesn't carry this skill with it** — a subagent starts fresh and inherits
none of it. Write the ticket body yourself and hand off only the search-and-create
step. Never let a subagent invent its own section layout.

---

## Example

```
Export saved reports as CSV

Overview

As a user, I'd like to download a saved report as a CSV so I can work with it in a
spreadsheet. Save time by exporting from the report page instead of copying tables.

Acceptance Criteria

- The report page has an "Export CSV" action that downloads the current report
- [If large reports time out in the browser] timeboxed investigation on generating
  the export server-side

Implementation Notes

- Requires investigation to see if client-side generation handles the largest reports
- Put behind a feature flag
```
