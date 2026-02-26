#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="${1:?Usage: deploy-vercel.sh <site_dir>}"
NAME="${2:-}"

cd "$SITE_DIR"

# Ensure Vercel sees this as a static site.
# It will auto-detect; we also pass --yes for non-interactive.
# --prod makes it a production deployment (gives a stable *.vercel.app URL)
OUT="$(vercel --prod --yes 2>&1 | tail -n 5)"

echo "=== VERCEL OUTPUT ==="
echo "$OUT"

# Print the first URL-looking token we see
URL="$(echo "$OUT" | grep -Eo 'https?://[^ ]+' | head -n 1 || true)"
if [[ -n "$URL" ]]; then
  echo "✅ LIVE_URL=$URL"
else
  echo "⚠️ Deployed, but could not parse URL. Check Vercel output above."
fi
