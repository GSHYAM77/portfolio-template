#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./scripts/new-site-repo-and-deploy.sh "bmw-3-series" "BMW 3 Series" "auto"
# NAME must be repo-safe slug.

NAME="${1:?slug required}"
TITLE="${2:-$NAME}"
STYLEPACK="${3:-modern-saas}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 1) Generate the site into data/outputs/sites/<name>
# Your existing generator should do this; adjust if your args differ
"$ROOT/scripts/new-site.sh" "$NAME" "$TITLE" "$STYLEPACK"

SITE_DIR="$ROOT/data/outputs/sites/$NAME"

# 2) Verify (hard gate)
"$ROOT/scripts/verify-site.sh" "$SITE_DIR"

# 3) Create + push a new GitHub repo with the generated site
# Your existing script should do this; adjust if your args differ
"$ROOT/scripts/new-site-repo.sh" "$NAME"

# 4) Deploy to Vercel from the generated site folder
"$ROOT/scripts/deploy-vercel.sh" "$SITE_DIR" "$NAME"
