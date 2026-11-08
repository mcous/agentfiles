---
name: stack
description: >
  Building and reviewing a stack of PRs with jj, linked on GitHub with `gh stack link`. Use whenever
  work lands in a stack, at the end of every chunk of agent work on one, and when
  asked to "open the review pane", "refresh the stack review", or submit a stack.
  Covers per-entry PR description drafts, a Hunk review pane in Herdr, and posting the
  drafts. Invoked with /stack.
user-invocable: true
---

# Stacks

A stack is an ordered list of jj bookmarks, each one a PR. Michael
reviews one entry at a time in a Hunk pane, with that entry's PR description at the top
of the diff.

Every history change here goes through `jj`. The only `git` call is the
`git diff --no-index` below, which touches no repo. No `gh stack` command other than
`link`. If the repo has no `.jj/`, ask before running `jj git init --colocate`.

## After every chunk of work

Run all three steps before reporting back, even if only one entry changed. A pane
showing a stale diff is worse than no pane.

1. **Restack** per *Git history* in AGENTS.md. The stack is the bookmarks between
   `trunk()` and the top entry, listed top first:

   ```sh
   jj log --no-graph -r 'bookmarks() & trunk()..<top>' \
     -T 'local_bookmarks.map(|b| b.name()).join(" ") ++ "\n"'
   ```

   Each entry's base is the entry below it; the bottom entry's base is `trunk()`.
   With nothing reviewed, `jj rebase -b <bottom> -d 'trunk()'` restacks the whole
   stack and its bookmarks follow. Once any entry is reviewed, use the jj column of
   the table in *Git history* instead.
2. **Refresh each description draft** that the chunk touched, following the
   `pr-description` skill. Drafts live outside the repo, one per bookmark:

   ```
   ~/.local/state/agentfiles/stack/<repo>/<bookmark>.md
   ```

   The draft is the PR body and nothing else, footer included. A renamed bookmark
   moves its draft.
3. **Open or refresh the review pane** below.

## Review pane

Each entry's patch puts the description first so it sorts to the top:

```sh
state=~/.local/state/agentfiles/stack/<repo>
{ (cd "$state" && git diff --no-index /dev/null "<bookmark>.md")
  jj diff --git --from <base> --to <bookmark>
} > "$state/<bookmark>.patch"
```

Review panes sit beside the chat, as many as the window fits: read the tab width
from `herdr pane layout --pane "$HERDR_PANE_ID"` (`.result.layout.area.width`) and
allow one pane per 90 columns past the first 90, minimum one. Fill them with the
entry Michael named, else the lowest entries this chunk changed. Open, refresh, and
carry notes across reloads per the `draft-review` skill, with `<repo>` as each pane's
`--cwd`. A note on code counts as addressed the same way a note on the description
does.

When there are more entries than panes, switching is a reload with the other entry's
patch, and only once the current entry has no unaddressed notes; otherwise ask.

## Submitting

Only when Michael asks to push or submit.

jj pushes; `gh` only creates PRs and links them. Never pass bookmark names to
`gh stack link` or run `gh stack submit`, since both push.

1. `jj git push -b <bookmark>` for every entry, bottom first.
2. For each entry without a PR, bottom first:
   `gh pr create --head <bookmark> --base <base-bookmark> --body-file <state>/<bookmark>.md`.
   For one that has a PR, run `gh pr edit <bookmark> --body-file …` only if its draft changed.
3. `gh stack link <pr> <pr> …` with PR numbers, bottom to top.

From a jj workspace, add `-R <owner>/<repo>` to every `gh` call.

The drafts never enter the repo, so nothing needs stripping before a push.
