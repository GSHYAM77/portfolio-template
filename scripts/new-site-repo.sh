#!/usr/bin/env bash
set -euo pipefail

NAME=""
VIS="public"
SOURCE="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2;;
    --vis) VIS="${2:-}"; shift 2;;   # public|private
    --source) SOURCE="${2:-}"; shift 2;;
    -h|--help)
      echo "Usage: new-site-repo.sh --name <slug> [--vis public|private] [--source <dir>]"
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

[[ -n "$NAME" ]] || { echo "Missing --name"; exit 1; }
[[ -d "$SOURCE" ]] || { echo "Source dir not found: $SOURCE"; exit 1; }

# Auto-suffix if repo exists
BASE="$NAME"
n=1
while gh repo view "GSHYAM77/$NAME" >/dev/null 2>&1; do
  n=$((n+1))
  NAME="${BASE}-${n}"
done
echo "✅ Using repo name: $NAME"

cd "$SOURCE"

# Ensure clean git state in SOURCE (important)
rm -rf .git
git init
git add -A
git commit -m "Initial site: $NAME" >/dev/null 2>&1 || true

# Create the repo first (no --source, no --push)
if [[ "$VIS" == "private" ]]; then
  gh repo create "GSHYAM77/$NAME" --private --confirm
else
  gh repo create "GSHYAM77/$NAME" --public --confirm
fi

# Force-set origin to the new repo, then push
REMOTE="git@github.com:GSHYAM77/$NAME.git"
git remote remove origin >/dev/null 2>&1 || true
git remote add origin "$REMOTE"

# Push main (or master if your default is master)
git branch -M main
git push -u origin main

echo "✅ https://github.com/GSHYAM77/$NAME"
