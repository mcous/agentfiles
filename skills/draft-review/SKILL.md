---
name: draft-review
description: >
  Review an outbound draft line by line in a Hunk pane instead of in chat. Use whenever
  written comms are drafted for Michael's approval before posting: PR descriptions,
  Linear tickets, GitHub issues and comments, Slack posts, Notion pages, reply drafts.
  Covers the draft file, opening and refreshing the Hunk pane in Herdr, carrying
  Michael's notes across revisions, and posting. Invoked with /draft-review.
user-invocable: true
---

# Draft review

Michael reviews outbound drafts in Hunk, leaving notes on the lines he wants changed.
The draft file is the single source of truth: what's in it is exactly what gets posted.

Outside Herdr (`HERDR_ENV` unset), show the draft in chat instead and skip the rest.

## The draft

One Markdown file per draft, outside any repo:

```
~/.local/state/agentfiles/drafts/<slug>.md
```

`<slug>` names the thing, e.g. `linear-abc-123`, `slack-deploy-freeze`, `pr-web-482`.
The file holds the post body and nothing else, LLM-attribution footer included. A
title or other metadata the destination keeps separately goes in chat, not the file.

The `stack` skill keeps its own drafts and builds its own patch; everything from
*Review pane* down applies to it unchanged.

## Review pane

Build the patch so the whole draft shows as added lines:

```sh
drafts=~/.local/state/agentfiles/drafts
(cd "$drafts" && git diff --no-index /dev/null "<slug>.md") > "$drafts/<slug>.patch"
```

`git diff --no-index` exits 1 when files differ; that is not a failure, and it
touches no repo.

Open the review in a vertical Herdr pane to the right of the chat, not a new tab,
whatever the layout. Follow the `herdr` skill for the environment check and current
CLI syntax.

```sh
herdr pane split --current --direction right --cwd "$drafts" --no-focus
herdr pane run <new-pane-id> hunk patch "$drafts/<slug>.patch"
```

Read the pane ID from `.result.pane.pane_id`. Then tell Michael the pane is open, in
one line, and wait for notes. Use a tab only when he asks for one.

## Revising

Michael's notes arrive in the Hunk session, not chat. Read them with
`hunk session comment list <id> --type all --json` (find `<id>` with
`hunk session list --json`, matching `sourceLabel` on the patch path). Follow the
`hunk-review` skill for anything else in the session CLI.

After editing the draft, reload the live session in place rather than reopening, so
the notes stay. Notes survive a reload but keep their old line numbers, so re-anchor
them:

1. **Before rebuilding the patch**, snapshot the notes and record the text of each
   anchored line from the old patch.
2. **Drop addressed notes.** A note is addressed when this revision acted on it;
   remove it with `hunk session comment rm`. Everything else, replies included, is
   unaddressed.
3. **Rebuild and reload:** `hunk session reload <id> -- patch <patch>`.
4. **Re-anchor unaddressed notes.** Find each recorded line in the new patch. If it
   moved, `rm` the note and re-add it at the new line with its original `--author` and
   body, then its replies with `--reply-to`. If the line is gone, re-add it on the
   nearest surviving line of that file, or line 1 of the patch when the file is gone,
   with the old line quoted in the summary.

Notes re-added through the CLI become agent notes, which start hidden, so pass
`--focus` on the first one. When the session was closed, open fresh; its notes are
gone and there is nothing to carry.

A question in a note gets answered in chat or with a reply note, not by guessing an
edit.

## Posting

Only when Michael says to post. Post the file's contents verbatim, with no edits after
his last look. If the draft changed since then, refresh the pane and wait again.

After posting, close the pane and delete the draft and its patch.
