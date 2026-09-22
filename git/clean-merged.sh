#!/usr/bin/env bash
# clean-merged.sh - delete local branches already merged into the base branch.
#
# Why: after a few weeks of feature branches, `git branch` output is a wall of
# dead branches. This deletes the ones that are fully merged, safely.
#
# Usage:
#   ./clean-merged.sh                 # dry run against origin/main (default)
#   ./clean-merged.sh main            # base branch
#   ./clean-merged.sh main --delete   # actually delete
#
# Exit codes:
#   0 = success, 1 = not a git repo
#
# Gotchas:
#   - Defaults to DRY RUN. You must pass --delete to remove anything. I added
#     this after deleting a branch I was mid-review on.
#   - Only deletes branches whose commits are merged into the base. Branches
#     with unmerged work are never touched, even with --delete.
#   - Never deletes the base branch or the currently checked-out branch.
#   - Run `git fetch --prune` first if you want the base to be up to date;
#     this script does it for you.
set -euo pipefail

base="${1:-main}"
mode="${2:-}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "not inside a git repository" >&2
  exit 1
fi

# Make sure we compare against the freshest base.
git fetch --prune --quiet origin "$base" 2>/dev/null || \
  echo "warning: could not fetch origin/$base; using local $base" >&2

# Prefer the remote ref if it exists, fall back to the local branch.
if git show-ref --verify --quiet "refs/remotes/origin/$base"; then
  target="origin/$base"
else
  target="$base"
fi

current="$(git rev-parse --abbrev-ref HEAD)"

# --merged lists branches whose tip is an ancestor of target.
merged="$(git branch --merged "$target" \
  | sed 's/^[* ] //' \
  | grep -vxE "$base|main|master|develop|$current" || true)"

if [[ -z "$merged" ]]; then
  echo "nothing to clean up against $target."
  exit 0
fi

echo "branches merged into $target:"
echo "$merged" | sed 's/^/  /'

if [[ "$mode" != "--delete" ]]; then
  echo
  echo "dry run. re-run with: $0 $base --delete"
  exit 0
fi

while IFS= read -r branch; do
  [[ -z "$branch" ]] && continue
  # -d refuses to delete unmerged branches, which is a nice extra guardrail.
  if git branch -d "$branch"; then
    echo "deleted $branch"
  else
    echo "skipped $branch (not fully merged?)" >&2
  fi
done <<< "$merged"
