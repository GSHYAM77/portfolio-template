#!/usr/bin/env bash
set -euo pipefail
# Strip UTF-8 NBSP (C2 A0) from text files that commonly get pasted/edited
TARGETS=(
  presets/*.json
  scripts/*.sh
  js/*.js
  *.html
  content/*.json
)

for g in "${TARGETS[@]}"; do
  for f in $g; do
    [[ -f "$f" ]] || continue
    perl -pi -pe 's/\xC2\xA0/ /g' "$f"
  done
done

echo "✅ NBSP sanitized"
