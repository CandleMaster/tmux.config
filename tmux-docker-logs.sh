
#!/usr/bin/env bash

set -euo pipefail

FILTERS=("$@")

# Ensure we're inside tmux
if [ -z "${TMUX:-}" ]; then
  echo "This script must be run inside tmux"
  exit 1
fi

# Get running container names
containers=$(docker ps --format '{{.Names}}')

# Always exclude mongodbb containers
containers=$(echo "$containers" | grep -v 'mongodb' | grep -v 'pg' | grep -v 'local-aws' || true)

# If filters were provided, apply them (OR match)
if [ "${#FILTERS[@]}" -gt 0 ]; then
  REGEX=$(IFS='|'; echo "${FILTERS[*]}")
  containers=$(echo "$containers" | grep -E "$REGEX" || true)
fi

if [ -z "$containers" ]; then
  echo "No running containers match filters (excluding mongodb and pg)"
  exit 0
fi

first=true

tmux split-window

for c in $containers; do
  if $first; then
    tmux select-pane -T "$c"
    tmux send-keys "docker logs -f $c" C-m
    first=false
  else
    pane_id=$(tmux split-window -v -P -F '#{pane_id}' "docker logs -f $c")
    tmux select-pane -t "$pane_id" -T "$c"
    tmux select-layout tiled
  fi
done

