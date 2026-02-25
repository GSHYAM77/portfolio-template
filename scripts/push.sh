#!/usr/bin/env bash
set -euo pipefail
MSG="${1:-update}"

# Stash any local changes before pulling
git stash push -u -m "autostash-before-pull" >/dev/null || true
git pull --rebase

# Re-apply stash if it existed
git stash list | grep -q "autostash-before-pull" && git stash pop >/dev/null || true

# Commit only if there are changes
if [[ -z "$(git status --porcelain)" ]]; then
  echo "No changes to push."
  exit 0
fi

git add -A
git commit -m "$MSG"
git push
