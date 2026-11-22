#!/bin/sh
# One pass of the drop folders: install anything that has finished landing, then gate it.
# Called in a loop by the file watcher; safe to run by hand.
#
#   sh tools/fetch_assets/watch_install.sh [model-name]
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
MODEL="${1:-generated}"
DROP="tools/fetch_assets/drop"
did=0

for book in emotions pets; do
    dir="$DROP/$book"
    [ -d "$dir" ] || continue
    stage="$dir/_stage"; done_dir="$dir/_installed"
    mkdir -p "$stage" "$done_dir"

    # Only files that stopped changing a minute ago. A half-written PNG installs as a
    # corrupt image and the gate cannot tell the difference — it checks dimensions, not
    # whether the bottom half of the file arrived.
    found=0
    for f in $(find "$dir" -maxdepth 1 -type f -mmin +1 \
               \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
                  -o -iname '*.webp' -o -iname '*.heic' \) 2>/dev/null); do
        mv "$f" "$stage/"; found=1
    done
    # A map.json is copied, not moved: it names files across several batches.
    [ -f "$dir/map.json" ] && cp "$dir/map.json" "$stage/" 2>/dev/null || true
    [ "$found" = "0" ] && continue

    out=$(python3 -I tools/fetch_assets/install_local.py "$book" "$stage" "$MODEL" 2>&1) || {
        echo "INSTALL FAILED for $book: $(echo "$out" | tail -2 | tr '\n' ' ')"
        mv "$stage"/* "$dir/" 2>/dev/null || true      # put them back for a human look
        continue
    }
    echo "$out" | grep -E "installed|skipped" | sed "s/^/  /"
    mv "$stage"/*.jpg "$stage"/*.jpeg "$stage"/*.png "$stage"/*.webp "$stage"/*.heic "$done_dir/" 2>/dev/null || true
    rm -f "$stage/map.json"
    python3 -I tools/fetch_assets/provenance.py "$book" image >/dev/null 2>&1 || true
    did=1
done

if [ "$did" = "1" ]; then
    if sh tools/check_assets.sh >/tmp/gate_assets.log 2>&1; then
        echo "  gate: green"
    else
        echo "  GATE RED: $(grep -A3 FAILED /tmp/gate_assets.log | tail -3 | tr '\n' ' ')"
    fi
fi
