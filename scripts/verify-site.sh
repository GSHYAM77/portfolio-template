#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
fail(){ echo "❌ VERIFY FAIL: $1"; exit 1; }

[[ -f "$ROOT/index.html" ]] || fail "missing index.html"
[[ -f "$ROOT/js/main.js" ]] || fail "missing js/main.js"
[[ -f "$ROOT/css/styles.css" ]] || fail "missing css/styles.css"
[[ -f "$ROOT/content/site.json" ]] || fail "missing content/site.json"

# Favicons (at least one)
if [[ ! -f "$ROOT/assets/favicon.ico" && ! -f "$ROOT/assets/favicon-32x32.png" && ! -f "$ROOT/assets/favicon-16x16.png" ]]; then
  fail "missing favicons in assets/"
fi

# Credit line
grep -Rqi "gshyamvp.com" "$ROOT" || fail "missing gshyamvp.com credit"

# Dark/light toggle hook
grep -Rqi 'id="modeToggle"' "$ROOT/index.html" || fail "missing modeToggle button in HTML"

# Must have CTA
python3 - <<PY
import json,sys
d=json.load(open("$ROOT/content/site.json"))
cta=(d.get("hero",{}).get("cta",{}))
ok=bool(cta.get("text")) and bool(cta.get("href"))
sys.exit(0 if ok else 1)
PY
[[ $? -eq 0 ]] || fail "missing hero.cta text/href"

# Must have images (gallery.items >= 6)
python3 - <<PY
import json,sys
d=json.load(open("$ROOT/content/site.json"))
items=d.get("gallery",{}).get("items",[])
sys.exit(0 if isinstance(items,list) and len(items)>=6 else 1)
PY
[[ $? -eq 0 ]] || fail "gallery.items must have >= 6 images"

# Must have clean-url pages referenced by nav (if nav uses hrefs starting with /)
python3 - <<'PY'
import json, os, sys
root=os.environ.get("ROOT_DIR",".")
d=json.load(open(root+"/content/site.json"))
links=(d.get("nav",{}).get("links",[]))
routes=[]
for x in links:
  if isinstance(x,dict):
    href=x.get("href","")
    if href.startswith("/") and href.endswith("/"):
      routes.append(href.strip("/"))
for r in routes:
  path=os.path.join(root,r,"index.html")
  if not os.path.exists(path):
    print("missing page for route:", r)
    sys.exit(1)
sys.exit(0)
PY
ROOT_DIR="$ROOT"
