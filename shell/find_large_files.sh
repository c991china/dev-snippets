#!/usr/bin/env bash
# find_large_files.sh - list the N largest files under a path.
#
# Why: "disk is full, where did it go" is a recurring 3am question. `du -sh *`
# only goes one level deep; this walks the whole tree and sorts by size.
#
# Usage:
#   ./find_large_files.sh [path] [count] [min_size]
#   ./find_large_files.sh /var 20
#   ./find_large_files.sh /home 50 +10M      # only files >10MB
#
# Exit codes:
#   0 = success, 1 = path not found
#
# Gotchas:
#   - Uses GNU find's -printf, which macOS/BSD find does NOT support. On macOS,
#     `brew install findutils` and call `gfind`, or swap in `-exec stat`.
#   - -xdev keeps it on one filesystem so you don't wander into mounted network
#     shares or /proc. Remove it if you want everything.
#   - Needs permission to stat files. Run with sudo to see root-owned stuff;
#     without it you'll silently miss files you can't read.
#   - Sorting by the numeric byte count, not the human string, so "2G" doesn't
#     sort before "500M" by accident.
set -euo pipefail

path="${1:-.}"
count="${2:-20}"
min_size="${3:-}"

if [[ ! -d "$path" ]]; then
  echo "path not found: $path" >&2
  exit 1
fi

# Build the find command. -size takes a filter like +10M if provided.
find_args=( "$path" -xdev -type f -printf '%s\t%p\n' )
if [[ -n "$min_size" ]]; then
  find_args=( "$path" -xdev -type f -size "$min_size" -printf '%s\t%p\n' )
fi

echo "top ${count} largest files under ${path}:"
# Sort numerically, newest biggest first, then humanize with awk so we don't
# depend on `numfmt` being installed.
find "${find_args[@]}" 2>/dev/null \
  | sort -rn \
  | head -n "$count" \
  | awk -F'\t' '
    function human(b,   u,i) {
      split("B KB MB GB TB PB", u, " ");
      i = 1;
      while (b >= 1024 && i < 6) { b /= 1024; i++ }
      return sprintf("%.1f%s", b, u[i]);
    }
    { printf "%8s  %s\n", human($1), $2 }
  '
