#!/usr/bin/env bash
set -euo pipefail

PRESET="${1:-}"
if [[ -z "$PRESET" ]]; then
  echo "Usage: scripts/use-preset.sh <portfolio|local-business|campaign-services>"
  exit 1
fi

SRC="presets/${PRESET}.json"
DST="content/site.json"

if [[ ! -f "$SRC" ]]; then
  echo "Preset not found: $SRC"
  exit 1
fi

cp "$SRC" "$DST"
echo "Applied preset: $SRC -> $DST"
