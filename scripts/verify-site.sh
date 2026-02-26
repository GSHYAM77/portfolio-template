#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
fail(){ echo "❌ VERIFY FAIL: $1"; exit 1; }

echo "[1/5] files"
[[ -f "$ROOT/index.html" ]] || fail "missing index.html"
[[ -f "$ROOT/js/main.js" ]] || fail "missing js/main.js"
[[ -f "$ROOT/css/styles.css" ]] || fail "missing css/styles.css"
[[ -f "$ROOT/content/site.json" ]] || fail "missing content/site.json"

echo "[2/5] favicons"
if [[ ! -f "$ROOT/assets/favicon.ico" && ! -f "$ROOT/assets/favicon-32x32.png" && ! -f "$ROOT/assets/favicon-16x16.png" ]]; then
  fail "missing favicons in assets/"
fi

echo "[3/5] credit + toggle"
grep -Rqi "gshyamvp.com" "$ROOT" || fail "missing gshyamvp.com credit"
grep -Rqi 'id="modeToggle"' "$ROOT/index.html" || fail "missing modeToggle"

echo "[4/5] hero CTA"
python3 - <<PYIN
import json,sys
d=json.load(open("$ROOT/content/site.json"))
cta=d.get("hero",{}).get("cta",{})
sys.exit(0 if cta.get("text") and cta.get("href") else 1)
PYIN
echo "  ok"

echo "[5/5] gallery images (>=6)"
python3 - <<PYIN
import json,sys
d=json.load(open("$ROOT/content/site.json"))
items=d.get("gallery",{}).get("items",[])
sys.exit(0 if isinstance(items,list) and len(items)>=6 else 1)
PYIN
echo "  ok"

echo "✅ verify-site passed for $ROOT"
