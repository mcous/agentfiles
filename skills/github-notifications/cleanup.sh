#!/usr/bin/env bash
# Mark notifications for merged or closed PRs as done.
# GitHub's UI doesn't filter by PR state natively — this fills that gap.
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "Dry run — no notifications will be marked done."
fi

STATE_DIR="$HOME/.config/agentfiles/state"
TIMESTAMP_FILE="$STATE_DIR/notifications-last-cleanup"

# Build query: all=true to include read-but-not-dismissed; since= to skip already-processed
QUERY="notifications?all=true"
if [[ -f "$TIMESTAMP_FILE" ]]; then
  SINCE=$(cat "$TIMESTAMP_FILE")
  QUERY="$QUERY&since=$SINCE"
fi

echo "Fetching notifications..."

NOTIFICATIONS=$(gh api "$QUERY" --paginate -q '.[] | select(.subject.type == "PullRequest") | {id: .id, title: .subject.title, url: .subject.url} | @json')

if [[ -z "$NOTIFICATIONS" ]]; then
  echo "No PR notifications found."
  exit 0
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Check all PR states in parallel, preserving original order via index-named files
INDEX=0
while IFS= read -r notification; do
  THREAD_ID=$(echo "$notification" | jq -r '.id')
  TITLE=$(echo "$notification" | jq -r '.title')
  PR_URL=$(echo "$notification" | jq -r '.url')

  (
    PR_STATE=$(gh api "$PR_URL" -q '.state' 2>/dev/null || echo "unknown")
    if [[ "$PR_STATE" == "closed" ]]; then
      printf '%s\t%s\n' "$THREAD_ID" "$TITLE" > "$TMPDIR/$(printf '%05d' "$INDEX")"
    fi
  ) &
  INDEX=$((INDEX + 1))
done <<< "$NOTIFICATIONS"

wait

# Collect results and act
DONE=0

for f in "$TMPDIR"/*; do
  [[ -e "$f" ]] || continue
  THREAD_ID=$(awk -F'\t' '{print $1}' "$f")
  TITLE=$(awk -F'\t' '{print $2}' "$f")
  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry run] would mark done: $TITLE"
  else
    gh api -X DELETE "/notifications/threads/$THREAD_ID" 2>/dev/null || true
    echo "  marked done: $TITLE"
  fi
  DONE=$((DONE + 1))
done

TOTAL=$(echo "$NOTIFICATIONS" | wc -l | tr -d ' ')
SKIPPED=$((TOTAL - DONE))

echo ""
echo "Done: $DONE notification(s) marked done, $SKIPPED skipped (PR still open)."

# Save timestamp (skip for dry runs so the window isn't advanced)
if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "$STATE_DIR"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "$TIMESTAMP_FILE"
fi
