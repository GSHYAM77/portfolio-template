#!/usr/bin/env bash
set -euo pipefail
PORT=8099

python3 -m http.server "$PORT" >/tmp/site_server.log 2>&1 &
PID=$!
cleanup(){ kill "$PID" 2>/dev/null || true; }
trap cleanup EXIT

sleep 0.6

check_page () {
  local path="$1"
  local html
  html="$(curl -fsS "http://127.0.0.1:$PORT$path")"

  # Must load the renderer JS and CSS
  echo "$html" | grep -q 'js/main.js' || { echo "FAIL: missing js/main.js on $path"; exit 1; }
  echo "$html" | grep -q 'css/styles.css' || { echo "FAIL: missing css/styles.css on $path"; exit 1; }

  echo "OK: $path (static refs present)"
}

# Check HTML pages exist
for path in "/" "/services/" "/about/" "/inventory/" "/contact/"; do
  check_page "$path"
done

# Check content JSON is reachable + valid
curl -fsS "http://127.0.0.1:$PORT/content/site.json" >/tmp/site.json
python3 -m json.tool /tmp/site.json >/dev/null
echo "OK: /content/site.json reachable + valid JSON"

# Optional: verify one style pack file exists
curl -fsS "http://127.0.0.1:$PORT/styles/packs/modern-saas.json" >/dev/null
echo "OK: style pack reachable"

echo "✅ Smoke test passed"
