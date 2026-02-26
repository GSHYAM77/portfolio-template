#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./scripts/new-site-repo-and-deploy.sh <slug> <email> <brand_hex> <preset> <stylepack>

NAME="${1:?slug required}"
EMAIL="${2:?email required}"
BRAND="${3:?brand hex required}"
PRESET="${4:-local-business}"
STYLEPACK="${5:-}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/sanitize-nbsp.sh" >/dev/null 2>&1 || true

echo "== Generating =="
if [[ -n "$STYLEPACK" ]]; then
  "$ROOT/scripts/new-site.sh" --name "$NAME" --email "$EMAIL" --brand "$BRAND" --preset "$PRESET" --stylepack "$STYLEPACK"
else
  "$ROOT/scripts/new-site.sh" --name "$NAME" --email "$EMAIL" --brand "$BRAND" --preset "$PRESET"
fi

SITE_DIR="$ROOT/data/outputs/sites/$NAME"

echo "== Verifying =="
"$ROOT/scripts/verify-site.sh" "$SITE_DIR"

echo "== Creating + pushing GitHub repo =="
"$ROOT/scripts/new-site-repo.sh" --name "$NAME" --vis public --source "$SITE_DIR"

echo "== Deploying to Vercel =="
"$ROOT/scripts/deploy-vercel.sh" "$SITE_DIR"
