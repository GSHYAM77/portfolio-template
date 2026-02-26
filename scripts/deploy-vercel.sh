#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="${1:?Usage: deploy-vercel.sh <site_dir>}"

cd "$SITE_DIR"

# Non-interactive production deploy
OUT="$(vercel --prod --yes 2>&1 | tail -n 30)"

echo "=== VERCEL OUTPUT (tail) ==="
echo "$OUT"

URL="$(echo "$OUT" | grep -Eo 'https?://[^ ]+' | head -n 1 || true)"
if [[ -n "$URL" ]]; then
  echo "✅ LIVE_URL=$URL"
else
  echo "⚠️ Deployed, but could not parse URL from output."
  exit 2
fi
