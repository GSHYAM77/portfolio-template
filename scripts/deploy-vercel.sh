#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="${1:?Usage: deploy-vercel.sh <site_dir>}"
cd "$SITE_DIR"

OUT="$(vercel --prod --yes 2>&1 | tail -n 60)"

echo "=== VERCEL OUTPUT (tail) ==="
echo "$OUT"

# Prefer Aliased URL, then Production URL
URL="$(echo "$OUT" | awk '/Aliased:/{print $2}' | tail -n 1)"
if [[ -z "$URL" ]]; then
  URL="$(echo "$OUT" | awk '/Production:/{print $2}' | tail -n 1)"
fi

if [[ -n "$URL" ]]; then
  echo "✅ LIVE_URL=$URL"
else
  echo "⚠️ Deployed, but could not parse LIVE_URL. Search above for 'Aliased:' or 'Production:'."
fi
