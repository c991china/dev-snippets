#!/usr/bin/env bash
# backup_rotate.sh - tar a directory and keep only the N newest archives.
#
# Why: I had a cron job that filled a disk because nobody deleted old backups.
# This is the small version I now drop on every box that needs one.
#
# Usage:
#   ./backup_rotate.sh <source_dir> <dest_dir> [keep_count]
#   ./backup_rotate.sh /srv/app /var/backups/app 7
#
# Exit codes:
#   0 = success, 1 = source missing, 2 = bad args
#
# Gotchas:
#   - Sorting by filename only works because the timestamp format is sortable
#     (YYYYmmdd-HHMMSS). If you change the naming, the rotation logic breaks.
#   - If two runs happen in the same second the filenames collide; tar will
#     happily overwrite. Add %N or a random suffix if that matters to you.
#   - The lock file prevents overlapping runs (a slow backup + a cron that fires
#     again). Stale lock after a crash: delete the file.
#   - GNU tar/stat assumed. On macOS, `stat -c` doesn't exist; use gstat from
#     coreutils or `find -newer` instead.
set -euo pipefail

src="${1:-}"
dest="${2:-}"
keep="${3:-7}"

if [[ -z "$src" || -z "$dest" ]]; then
  echo "usage: $0 <source_dir> <dest_dir> [keep_count]" >&2
  exit 2
fi

if [[ ! -d "$src" ]]; then
  echo "source dir does not exist: $src" >&2
  exit 1
fi

mkdir -p "$dest"

lock="${dest}/.backup.lock"
if ! mkdir "$lock" 2>/dev/null; then
  echo "another backup is running (lock: $lock)" >&2
  exit 1
fi
# always release the lock, even on error
trap 'rmdir "$lock" 2>/dev/null || true' EXIT

stamp="$(date +%Y%m%d-%H%M%S)"
base="$(basename "$src")"
archive="${dest}/${base}-${stamp}.tar.gz"

echo "backing up ${src} -> ${archive}"
# --exclude the lock dir just in case dest is inside src
tar -czf "$archive" -C "$(dirname "$src")" \
  --exclude='.backup.lock' "$base"

size="$(du -h "$archive" | cut -f1)"
echo "wrote ${archive} (${size})"

# Rotation: list newest-first, keep the first $keep, delete the rest.
# Guard against keep=0 by requiring at least 1.
(( keep < 1 )) && keep=1
mapfile -t old < <(ls -1t "${dest}/${base}-"*.tar.gz 2>/dev/null | tail -n +$((keep + 1)))
if (( ${#old[@]} > 0 )); then
  echo "removing ${#old[@]} old backup(s)"
  for f in "${old[@]}"; do
    rm -f -- "$f"
  done
fi

echo "done. keeping newest ${keep}."
