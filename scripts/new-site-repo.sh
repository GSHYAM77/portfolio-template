#!/usr/bin/env bash
set -euo pipefail

# Usage:
# scripts/new-site-repo.sh --name valley-golf-clubhouse --email sales@... --brand "#2d6a4f" --preset local-business --visibility public

NAME=""; EMAIL=""; BRAND=""; PRESET="local-business"; VIS="public"; STYLEPACK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2;;
    --email) EMAIL="${2:-}"; shift 2;;
    --brand) BRAND="${2:-}"; shift 2;;
    --preset) PRESET="${2:-}"; shift 2;;
    --stylepack) STYLEPACK="${2:-}"; shift 2;;
    --visibility) VIS="${2:-}"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

if [[ -z "$NAME" || -z "$EMAIL" || -z "$BRAND" ]]; then
  echo "Missing required flags: --name --email --brand"
  exit 1
fi

ROOT="/root/.openclaw/workspace-havoc/portfolio-template"
cd "$ROOT"

# Generate site bundle
if [[ -n "$STYLEPACK" ]]; then
  ./scripts/new-site.sh --name "$NAME" --email "$EMAIL" --brand "$BRAND" --preset "$PRESET" --stylepack "$STYLEPACK"
else
  ./scripts/new-site.sh --name "$NAME" --email "$EMAIL" --brand "$BRAND" --preset "$PRESET"
fi

SITE_DIR="$ROOT/data/outputs/sites/$NAME"
cd "$SITE_DIR"

# clean stray file if present
rm -f site.json 2>/dev/null || true

# Init git and push to new repo
git init
git add -A
git commit -m "Initial site: $NAME"

# Create repo (idempotent-ish: if exists, it will error; that's fine)
if [[ "$VIS" == "private" ]]; then
  gh repo create "GSHYAM77/$NAME" --private --source=. --remote=origin --push
else
  gh repo create "GSHYAM77/$NAME" --public --source=. --remote=origin --push
fi

echo "✅ Repo created and pushed: https://github.com/GSHYAM77/$NAME"
