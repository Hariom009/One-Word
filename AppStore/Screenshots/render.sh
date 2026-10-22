#!/bin/bash
# Renders frame.html into 2880x1800 App Store screenshots in v1/framed/. Needs Google Chrome.
set -euo pipefail
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
COUNT=$(grep -c '^    \["v1/' frame.html)
mkdir -p v1/framed
PROFILE=$(mktemp -d)
for ((i = 0; i < COUNT; i++)); do
  "$CHROME" --headless=new --user-data-dir="$PROFILE" --hide-scrollbars \
    --force-device-scale-factor=2 --window-size=1440,900 \
    --screenshot="$PWD/v1/framed/0$((i + 1)).png" "file://$PWD/frame.html?n=$i" 2>/dev/null
done
rm -rf "$PROFILE"
sips -g pixelWidth -g pixelHeight v1/framed/*.png | grep -v '^$'
