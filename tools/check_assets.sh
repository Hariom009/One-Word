#!/bin/sh
# The check for bundled media: every image and clip a dictionary names exists, every
# file in Pictures/ and Clips/ is named by some dictionary, and each one meets the
# format contract. Pure file check — no Swift to compile, because nothing here is
# logic; it is the one failure that is invisible in the simulator (a missing asset
# just draws nothing) and permanent in a release.
#
#   sh tools/check_assets.sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 -I - "$ROOT" <<'PY'
import json, os, subprocess, sys

root = sys.argv[1]
shared = os.path.join(root, "OneWord", "Shared")
pics = os.path.join(root, "OneWord", "Pictures")
clips = os.path.join(root, "OneWord", "Clips")
fail = []

def ok(msg): print(f"  ok  {msg}")

# EVERY bundled book, not just the live ones: a hidden book's JSON and its media
# both still ship, so a dangling reference in one is a file missing from a release
# whether or not the shelf is reachable. The live/hidden split is reported at the
# end, because bytes for a book nobody can open is worth seeing.
shelves = json.load(open(os.path.join(shared, "Shelves.json")))["shelves"]
live = sorted([b for b, on in shelves.items() if on])
books = sorted(b for b in shelves if os.path.exists(os.path.join(shared, f"{b}.json")))
print("bundled books:", ", ".join(books))
print("live:", ", ".join(live))

def listing(folder):
    if not os.path.isdir(folder): return {}
    return {f.rsplit(".", 1)[0]: os.path.join(folder, f)
            for f in os.listdir(folder) if not f.startswith(".")}

have_pics, have_clips = listing(pics), listing(clips)
used_pics, used_clips = set(), set()

print("\nreferences resolve")
shipped = {}
for book in books:
    path = os.path.join(shared, f"{book}.json")
    if not os.path.exists(path):      # "saved" is not a bundled file
        continue
    for w in json.load(open(path)):
        for field, have, used, folder in (("image", have_pics, used_pics, "Pictures"),
                                          ("clip", have_clips, used_clips, "Clips")):
            name = w.get(field)
            if not name: continue
            used.add(name)
            if name not in have:
                fail.append(f"{book}: {w['term']!r} names {field} {name!r}, missing from {folder}/")
            elif os.path.exists(have[name]):
                shipped[book] = shipped.get(book, 0) + os.path.getsize(have[name])
    ok(f"{book}")

print("\nnothing orphaned")
for label, have, used in (("Pictures", have_pics, used_pics), ("Clips", have_clips, used_clips)):
    orphans = sorted(set(have) - used)
    if orphans:
        fail.append(f"{label}/: {len(orphans)} file(s) no dictionary names: {', '.join(orphans[:5])}")
    else:
        ok(f"{label}/ — {len(have)} file(s), all referenced")

print("\nformat contract")
# 800px long edge, as the Picture Book set it. Bigger buys nothing: it draws into a
# 200-320pt box, and the bytes ship with every copy of the app.
oversize = []
for name, path in sorted(have_pics.items()):
    try:
        out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", path],
                             capture_output=True, text=True, timeout=20).stdout
        dims = [int(l.split(":")[1]) for l in out.splitlines() if ":" in l and l.split(":")[0].strip()
                in ("pixelWidth", "pixelHeight")]
        if dims and max(dims) > 800: oversize.append(f"{name} ({max(dims)}px)")
    except Exception:
        pass
if oversize: fail.append(f"over 800px on the long edge: {', '.join(oversize[:6])}")
else: ok(f"{len(have_pics)} image(s) within 800px")

# A clip carries no audio: the entry's own `sound` recording is the sound, and a clip
# with its own would talk over it and duck whatever the reader is listening to.
noisy, unchecked = [], 0
for name, path in sorted(have_clips.items()):
    try:
        out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a",
                              "-show_entries", "stream=index", "-of", "csv=p=0", path],
                             capture_output=True, text=True, timeout=20).stdout.strip()
        if out: noisy.append(name)
    except FileNotFoundError:
        unchecked += 1
    except Exception:
        unchecked += 1
if noisy: fail.append(f"clip(s) with an audio track: {', '.join(noisy)}")
elif unchecked: print(f"  --  {unchecked} clip(s) unchecked for audio (ffprobe not installed)")
else: ok(f"{len(have_clips)} clip(s) silent")

print("\nwhat the media weighs")
for book in sorted(shipped, key=lambda b: -shipped[b]):
    mark = "live  " if book in live else "hidden"
    print(f"  {mark}  {book:10} {shipped[book]/1e6:6.1f} MB")
hiding = sum(v for b, v in shipped.items() if b not in live)
if hiding:
    print(f"  -- {hiding/1e6:.1f} MB ships for books no one can open; "
          f"that is a shelf decision, not a gate failure")

if fail:
    print("\nFAILED")
    for f in fail: print("  -", f)
    sys.exit(1)
print("\nall checks passed")
PY
