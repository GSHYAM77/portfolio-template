#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-.}"
fail(){ echo "❌ VERIFY FAIL: $1"; exit 1; }

[[ -f "$ROOT/index.html" ]] || fail "missing index.html"
[[ -f "$ROOT/js/main.js" ]] || fail "missing js/main.js"
[[ -f "$ROOT/css/styles.css" ]] || fail "missing css/styles.css"
[[ -f "$ROOT/content/site.json" ]] || fail "missing content/site.json"

# Favicons
if [[ ! -f "$ROOT/assets/favicon.ico" && ! -f "$ROOT/assets/favicon-32x32.png" && ! -f "$ROOT/assets/favicon-16x16.png" ]]; then
  fail "missing favicons in assets/"
fi

# credit
grep -Rqi "gshyamvp.com" "$ROOT" || fail "missing gshyamvp.com credit"

# dark mode toggle
grep -Rqi 'id="modeToggle"' "$ROOT/index.html" || fail "missing modeToggle"

# CTA exists
python3 - <<PY
import json,sys
d=json.load(open("$ROOT/content/site.json"))
cta=d.get("hero",{}).get("cta",{})
sys.exit(0 if cta.get("text") and cta.get("href") else 1)
PY
[[ $? -eq 0 ]] || fail "missing hero.cta"

# at least 6 images
python3 - <<PY
import json,sys
d=json.load(open("$ROOT/content/site.json"))
items=d.get("gallery",{}).get("items",[])
sys.exit(0 if isinstance(items,list) and len(items)>=6 else 1)
PY
[[ $? -eq 0 ]] || fail "gallery.items must have >= 6 images"

echo "✅ verify-site passed"
