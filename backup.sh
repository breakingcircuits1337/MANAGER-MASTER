#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
snapshots_dir="$root_dir/backups/snapshots"
bare_dir="$root_dir/backups/bare.git"

do_snapshot=false
do_git=false

if [[ $# -eq 0 ]]; then
  do_snapshot=true
  do_git=true
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --snapshot) do_snapshot=true; shift ;;
    --git)      do_git=true;      shift ;;
    *) printf 'Unknown option: %s\n  Usage: %s [--snapshot] [--git]\n' "$1" "$0" >&2; exit 1 ;;
  esac
done

if [[ "$do_snapshot" == true ]]; then
  ts="$(date +%Y-%m-%d_%H%M%S)"
  dest="$snapshots_dir/$ts"
  mkdir -p "$dest"
  rsync -a --exclude='backups/' "$root_dir/" "$dest/"
  printf 'Snapshot created: %s\n' "$dest"
fi

if [[ "$do_git" == true ]]; then
  if [[ ! -d "$bare_dir" ]]; then
    git init --bare "$bare_dir"
    printf 'Initialized bare repo: %s\n' "$bare_dir"
  fi
  cd "$root_dir"
  git remote remove backup 2>/dev/null || true
  git remote add backup "$bare_dir"
  git push backup main --force
  printf 'Pushed to bare clone: %s\n' "$bare_dir"
fi
