#!/bin/bash
# Renders frame.html into 2880x1800 Mac App Store screenshots in framed/. Needs Google Chrome.
set -euo pipefail
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
COUNT=$(grep -c '^    \["raw/' frame.html)
mkdir -p framed
PROFILE=$(mktemp -d)
for ((i = 0; i < COUNT; i++)); do
  "$CHROME" --headless=new --user-data-dir="$PROFILE" --hide-scrollbars --allow-file-access-from-files \
    --force-device-scale-factor=2 --window-size=1440,900 \
    --screenshot="$PWD/framed/0$((i + 1)).png" "file://$PWD/frame.html?n=$i" 2>/dev/null
done
rm -rf "$PROFILE"
sips -g pixelWidth -g pixelHeight framed/*.png | grep -v '^$'
