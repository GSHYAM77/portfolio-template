#!/usr/bin/env bash
set -euo pipefail

# Usage:
# scripts/new-site-repo-and-deploy.sh <slug> <email> <brand_hex> [preset] [stylepack]
# Example:
# scripts/new-site-repo-and-deploy.sh bmw-3-series sales@example.com "#1e40af" local-business luxury-blackgold

NAME="${1:?slug required}"
EMAIL="${2:?email required}"
BRAND="${3:?brand hex required}"
PRESET="${4:-local-business}"
STYLEPACK="${5:-}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 1) Generate bundle
GEN_ARGS=(--name "$NAME" --email "$EMAIL" --brand "$BRAND" --preset "$PRESET")
if [[ -n "$STYLEPACK" ]]; then
  GEN_ARGS+=(--stylepack "$STYLEPACK")
fi

"$ROOT/scripts/new-site.sh" "${GEN_ARGS[@]}"

SITE_DIR="$ROOT/data/outputs/sites/$NAME"

# 2) Verify (hard gate)
"$ROOT/scripts/verify-site.sh" "$SITE_DIR"

# 3) Create + push repo from bundle
"$ROOT/scripts/new-site-repo.sh" "$NAME"

# 4) Deploy to Vercel
"$ROOT/scripts/deploy-vercel.sh" "$SITE_DIR"
