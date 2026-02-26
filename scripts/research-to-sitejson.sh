#!/usr/bin/env bash
set -euo pipefail

TOPIC="${1:?Usage: research-to-sitejson.sh \"topic\" <out_site_json>}"
OUT_JSON="${2:?Usage: research-to-sitejson.sh \"topic\" <out_site_json>}"
EMAIL="${3:-info@example.com}"
BRAND="${4:-#2563eb}"
STYLEPACK="${5:-modern-saas}"

[[ -n "${OPENROUTER_API_KEY:-}" ]] || { echo "Missing OPENROUTER_API_KEY env var"; exit 1; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Call OpenRouter (Claude Sonnet) with web search enabled via :online
curl -sS https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d @- > "$TMP" <<JSON
{
  "model": "anthropic/claude-3.5-sonnet:online",
  "response_format": { "type": "json_object" },
  "messages": [
    {
      "role": "system",
      "content": "You build informational websites. You MUST use web search. Return ONLY valid JSON. No markdown, no commentary."
    },
    {
      "role": "user",
      "content": "Create content/site.json for an informational website about: ${TOPIC}.\\n\\nHard requirements:\\n- Output MUST be a single JSON object with keys: meta, nav, hero, about, services, projects, gallery, faq, contact, footer.\\n- gallery.items MUST contain 8+ items with {src, alt} using direct https image URLs.\\n- Include strong CTA (hero.cta) and contact.email.\\n- Set meta.brandColor=${BRAND} and meta.stylePack=${STYLEPACK}.\\n- Footer must include creditLink=https://gshyamvp.com and creditName=gshyamvp.com.\\n- Add meta.sources as an array of URLs used.\\n\\nReturn ONLY JSON."
    }
  ]
}
JSON

# Extract the model JSON content safely
python3 - <<PY
import json, sys
raw=json.load(open("$TMP"))
txt=raw["choices"][0]["message"]["content"]
# Some models return JSON string; ensure it's parsed
if isinstance(txt, dict):
    data=txt
else:
    data=json.loads(txt)

# Force required fields
data.setdefault("meta", {})
data["meta"]["brandColor"] = "$BRAND"
data["meta"]["stylePack"] = "$STYLEPACK"
data.setdefault("contact", {})
data["contact"]["email"] = "$EMAIL"
data.setdefault("footer", {})
data["footer"]["creditLink"] = "https://gshyamvp.com"
data["footer"]["creditName"] = "gshyamvp.com"
data.setdefault("meta", {}).setdefault("sources", [])

# If gallery empty or missing, inject fallback topic-based images (always works)
g=data.setdefault("gallery", {})
items=g.get("items") or []
if len(items) < 8:
    topic="$TOPIC".replace(" ", ",")
    fallback=[
        {"src": f"https://source.unsplash.com/1600x900/?{topic},1", "alt": f"{topic} photo 1"},
        {"src": f"https://source.unsplash.com/1600x900/?{topic},2", "alt": f"{topic} photo 2"},
        {"src": f"https://source.unsplash.com/1600x900/?{topic},3", "alt": f"{topic} photo 3"},
        {"src": f"https://source.unsplash.com/1600x900/?{topic},4", "alt": f"{topic} photo 4"},
        {"src": f"https://source.unsplash.com/1600x900/?{topic},5", "alt": f"{topic} photo 5"},
        {"src": f"https://source.unsplash.com/1600x900/?{topic},6", "alt": f"{topic} photo 6"},
        {"src": f"https://source.unsplash.com/1600x900/?{topic},7", "alt": f"{topic} photo 7"},
        {"src": f"https://source.unsplash.com/1600x900/?{topic},8", "alt": f"{topic} photo 8"}
    ]
    g["sectionLabel"]=g.get("sectionLabel","Gallery")
    g["heading"]=g.get("heading","Photos")
    g["intro"]=g.get("intro","A quick look.")
    g["items"]=fallback

# Write output
out_path="$OUT_JSON"
with open(out_path,"w") as f:
    json.dump(data,f,indent=2)
    f.write("\n")
print("WROTE", out_path, "gallery_items=", len(data["gallery"]["items"]))
PY

# sanitize NBSP if any
./scripts/sanitize-nbsp.sh >/dev/null 2>&1 || true

# validate json
jq -e . "$OUT_JSON" >/dev/null
