#!/usr/bin/env bash
set -euo pipefail

NAME=""
EMAIL=""
BRAND=""
PRESET="local-business"
STYLEPACK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)  NAME="${2:-}"; shift 2;;
    --email) EMAIL="${2:-}"; shift 2;;
    --brand) BRAND="${2:-}"; shift 2;;
    --preset) PRESET="${2:-}"; shift 2;;
    --stylepack) STYLEPACK="${2:-}"; shift 2;;
    -h|--help)
      echo "Usage: scripts/new-site.sh --name <slug> --email <email> --brand <hex> [--preset portfolio|local-business|campaign-services] [--stylepack packname]"
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

if [[ -z "$NAME" || -z "$EMAIL" || -z "$BRAND" ]]; then
  echo "Missing required flags. Need --name, --email, --brand"
  exit 1
fi

SRC_PRESET="presets/${PRESET}.json"
if [[ ! -f "$SRC_PRESET" ]]; then
  echo "Preset not found: $SRC_PRESET"
  exit 1
fi

# Random style pack if not provided
if [[ -z "$STYLEPACK" ]]; then
  PACKS=(modern-saas local-trust luxury-blackgold sporty-bold minimal-paper)
  STYLEPACK="${PACKS[$RANDOM % ${#PACKS[@]}]}"
fi

OUT="data/outputs/sites/${NAME}"
mkdir -p "$OUT"

# Copy root bundle
cp -f index.html "$OUT/index.html"
mkdir -p "$OUT/css" "$OUT/js" "$OUT/assets" "$OUT/content" "$OUT/styles/packs"
cp -rf css/* "$OUT/css/" 2>/dev/null || true
cp -rf js/* "$OUT/js/" 2>/dev/null || true
cp -rf assets/* "$OUT/assets/" 2>/dev/null || true
cp -rf styles/packs/* "$OUT/styles/packs/" 2>/dev/null || true

# Clean URLs pages
mkdir -p "$OUT/about" "$OUT/services" "$OUT/inventory" "$OUT/contact"
cp -f "$OUT/index.html" "$OUT/about/index.html"
cp -f "$OUT/index.html" "$OUT/services/index.html"
cp -f "$OUT/index.html" "$OUT/inventory/index.html"
cp -f "$OUT/index.html" "$OUT/contact/index.html"

# Set page ids
python3 - <<PY
import pathlib
def set_page(file, page):
    p = pathlib.Path(file)
    s = p.read_text()
    s = s.replace("<body>", f'<body data-page="{page}">', 1)
    p.write_text(s)
set_page("$OUT/index.html", "home")
set_page("$OUT/about/index.html", "about")
set_page("$OUT/services/index.html", "services")
set_page("$OUT/inventory/index.html", "inventory")
set_page("$OUT/contact/index.html", "contact")
PY

# Write preset into content
cp -f "$SRC_PRESET" "$OUT/content/site.json"

# Patch meta/contact
python3 - <<PY
import json, pathlib
p = pathlib.Path("$OUT/content/site.json")
d = json.loads(p.read_text())
d.setdefault("meta", {})
d["meta"]["brandColor"] = "$BRAND"
d["meta"]["stylePack"] = "$STYLEPACK"
d.setdefault("contact", {})
d["contact"]["email"] = "$EMAIL"
p.write_text(json.dumps(d, indent=2) + "\n")
print("Wrote:", p)
print("Style pack:", "$STYLEPACK")
PY

cat > "$OUT/README.md" <<TXT
# $NAME

Generated from portfolio-template
Preset: $PRESET
Style pack: $STYLEPACK

Pages:
- /
- /about
- /services
- /inventory
- /contact

Edit content in: content/site.json
TXT

echo "✅ Generated site bundle at: $OUT"
echo "Preset: $PRESET | StylePack: $STYLEPACK | Email: $EMAIL | Brand: $BRAND"



# --- AUTO_CREATE_PAGES_FROM_NAV ---
# Create clean-url pages for any nav link objects like { "text": "...", "href": "/overview/" }
python3 - <<'PYIN'
import json, os, re, pathlib
site_dir=os.environ["SITE_DIR"]
data=json.load(open(os.path.join(site_dir,"content","site.json")))
links=data.get("nav",{}).get("links",[])
routes=[]
for x in links:
    if isinstance(x,dict):
        href=x.get("href","")
        if href.startswith("/") and href.endswith("/"):
            routes.append(href.strip("/"))

base = pathlib.Path(site_dir)
src = base/"index.html"
for r in routes:
    d = base/r
    d.mkdir(parents=True, exist_ok=True)
    (d/"index.html").write_text(src.read_text())

# set data-page for key routes (defaults to slug)
def set_page(path, page):
    t=pathlib.Path(path).read_text()
    if 'data-page="' in t:
        t=re.sub(r'data-page="[^"]+"', f'data-page="{page}"', t, count=1)
    else:
        t=t.replace("<body>", f'<body data-page="{page}">', 1)
    # absolute asset paths
    t=t.replace('href="./css/styles.css"','href="/css/styles.css"')
    t=t.replace('src="./js/main.js"','src="/js/main.js"')
    pathlib.Path(path).write_text(t)

set_page(base/"index.html","home")
for r in routes:
    set_page(base/r/"index.html", r)

PYIN
# --- END AUTO_CREATE_PAGES_FROM_NAV ---

