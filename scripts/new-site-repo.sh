#!/usr/bin/env bash
set -euo pipefail

NAME=""
VIS="public"
SOURCE="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2;;
    --vis) VIS="${2:-}"; shift 2;;
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

OWNER="GSHYAM77"

# Pick an available repo name (NAME, NAME-2, NAME-3, ...)
REPO="$NAME"
if gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  i=2
  while gh repo view "$OWNER/$NAME-$i" >/dev/null 2>&1; do
    i=$((i+1))
  done
  REPO="$NAME-$i"
fi

echo "✅ Using repo name: $REPO"

cd "$SOURCE"

# ensure clean git state in source dir
rm -rf .git
git init -b main
git add -A
git commit -m "Initial site: $REPO"

# create repo if needed
if [[ "$VIS" == "private" ]]; then
  gh repo create "$OWNER/$REPO" --private >/dev/null
else
  gh repo create "$OWNER/$REPO" --public >/dev/null
fi

# force origin + push
git remote remove origin >/dev/null 2>&1 || true
git remote add origin "git@github.com:$OWNER/$REPO.git"
git push -u origin main --force

echo "✅ https://github.com/$OWNER/$REPO"
