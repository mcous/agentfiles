---
name: github-notifications
description: Clear stale GitHub notifications — marks notifications for merged or closed PRs as done. Use when asked to "clean up notifications", "clear stale notifications", or tidy the GitHub inbox.
---

# GitHub notifications

Run `bash <this skill's directory>/cleanup.sh`. Pass `--dry-run` first when the user wants
a preview. It needs `gh` authenticated and `jq`.

The script only checks notifications newer than its last real run, tracked in
`~/.config/agentfiles/state/notifications-last-cleanup`. Report its
closing summary line and nothing else.
