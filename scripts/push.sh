#!/usr/bin/env bash
set -euo pipefail
MSG="${1:-update}"

git pull --rebase
if [[ -z "$(git status --porcelain)" ]]; then
  echo "No changes to push."
  exit 0
fi

git add -A
git commit -m "$MSG"
git push
