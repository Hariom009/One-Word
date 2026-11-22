#!/usr/bin/env python3
"""Rank candidates per term and build a contact sheet to choose from.

search.py returns whatever Commons matched, noise included — "bark" pulls tree bark
and a 1945 newsreel. This scores each candidate on whether its TITLE actually says
the animal and the behaviour, keeps the best few, fetches thumbnails and tiles them
into one sheet per batch so the choice can be made by eye rather than by filename.

Writes picks-<book>.json with the top-ranked candidate per term as a STARTING POINT.
Look at the sheet and correct it before running install.py — the ranking is a filter,
not a judgement.

    python3 -I shortlist.py pets image
"""
import json, os, re, subprocess, sys, time, urllib.parse, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
UA = "OneWordAssetTool/1.0 (offline dictionary asset sourcing)"
NOISE = ("logo", "animation", "diagram", "map", "chart", "coat of arms", "flag",
         "bark pine", "bark park", "tree bark", "barkly", "newsreel", "scholia")

def gerund(w):
    if w.endswith("ing"): return w
    return (w[:-1] if w.endswith("e") else w) + "ing"

def score(title, term, animal):
    """Does the title claim to show this animal doing this thing?"""
    t = title.lower()
    head = term.split()[-1].lower()
    s = 0
    if animal in t: s += 3
    if gerund(head) in t: s += 4          # "cat yawning" — the caption we want
    elif head in t: s += 1                # "bark" alone is usually the wrong bark
    if any(n in t for n in NOISE): s -= 6
    if re.search(r"\b(19|20)\d\d\b", t) and animal not in t: s -= 2
    s -= 0.001 * len(t)                   # all else equal, the plainer title
    return s

def thumbs(titles, width=320):
    """Ask the API for thumbnail URLs, in batches of 40.

    A thumbnail URL CANNOT be built by hand any more: Wikimedia rejects constructed
    ones with "Use thumbnail sizes listed on…" whatever width you pick, including the
    standard 320/640/800. Only `iiurlwidth` returns a URL that serves. Batching also
    turns 17 round trips into one, which matters because Commons throttles hard."""
    out = {}
    titles = list(titles)
    for i in range(0, len(titles), 40):
        batch = titles[i:i+40]
        url = "https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode({
            "action": "query", "format": "json", "titles": "|".join(batch),
            "prop": "imageinfo", "iiprop": "url", "iiurlwidth": width})
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.load(r)
        except Exception as e:
            print(f"    ! thumb batch: {e}", flush=True); continue
        for pg in d.get("query", {}).get("pages", {}).values():
            ii = (pg.get("imageinfo") or [{}])[0]
            if ii.get("thumburl"): out[pg["title"]] = ii["thumburl"]
        time.sleep(2)
    return out

def grab(url, dest, tries=4):
    """upload.wikimedia.org rate-limits separately from the API, so this backs off too.
    Returns False loudly rather than leaving a zero-byte file behind."""
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for a in range(tries):
        try:
            with urllib.request.urlopen(req, timeout=60) as r, open(dest, "wb") as f:
                f.write(r.read())
            if os.path.getsize(dest) > 2000: return True
            os.remove(dest); return False
        except urllib.error.HTTPError as e:
            if e.code != 429 or a == tries - 1:
                print(f"    ! thumb {e}", flush=True); return False
            time.sleep(4 * (a + 1))
        except Exception as e:
            print(f"    ! thumb {e}", flush=True); return False
    return False

def main():
    book, kind = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "image")
    cands = json.load(open(os.path.join(HERE, f"candidates-{book}-{kind}.json")))
    entries = json.load(open(os.path.join(HERE, "..", "..", "OneWord", "Shared", f"{book}.json")))
    pos = {w["term"]: w.get("partOfSpeech", "") for w in entries}

    sheets = os.path.join(HERE, "downloads", "_thumbs")
    os.makedirs(sheets, exist_ok=True)
    picks, ranked_all = {}, {}
    for term, hits in cands.items():
        animal = "cat" if "cat" in pos.get(term, "") else "dog"
        ranked = sorted(hits, key=lambda h: -score(h["title"], term, animal))
        ranked = [h for h in ranked if score(h["title"], term, animal) > 0][:4]
        ranked_all[term] = ranked
        if not ranked: continue
        picks[term] = ranked[0]["title"]
        print(f"  {term:20} {len(ranked)} kept  -> {ranked[0]['title'][5:60]}")

    # Thumbnails in one batch, after the ranking, so the slow part runs once.
    urls = thumbs(picks.values())
    shots = []
    for term, title in picks.items():
        if title not in urls: continue
        dest = os.path.join(sheets, re.sub(r"[^a-z0-9]+", "-", term.lower()) + ".jpg")
        if grab(urls[title], dest): shots.append((term, dest))
        time.sleep(0.6)

    json.dump(picks, open(os.path.join(HERE, f"picks-{book}.json"), "w"),
              ensure_ascii=False, indent=1)
    json.dump(ranked_all, open(os.path.join(HERE, f"ranked-{book}.json"), "w"),
              ensure_ascii=False, indent=1)

    # One tiled sheet per 12, so the whole book can be eyeballed in three looks.
    for i in range(0, len(shots), 12):
        batch = shots[i:i+12]
        sheet = os.path.join(sheets, f"sheet-{book}-{i//12+1}.jpg")
        args = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
        for _, f in batch: args += ["-i", f]
        n = len(batch)
        args += ["-filter_complex",
                 "".join(f"[{j}:v]scale=320:240:force_original_aspect_ratio=decrease,"
                         f"pad=320:240:(ow-iw)/2:(oh-ih)/2:color=black[v{j}];" for j in range(n))
                 + "".join(f"[v{j}]" for j in range(n)) + f"xstack=inputs={n}:layout="
                 + "|".join(f"{(j%4)*320}_{(j//4)*240}" for j in range(n)) + "[out]",
                 "-map", "[out]", "-frames:v", "1", sheet]
        try:
            subprocess.run(args, check=True, capture_output=True, timeout=180)
            print("  sheet:", sheet, "->", ", ".join(t for t, _ in batch))
        except Exception as e:
            print("  ! sheet failed:", e)

    print(f"\n{len(picks)}/{len(cands)} terms have a ranked candidate")
    print("picks written. LOOK AT THE SHEETS, fix picks-%s.json, then install.py" % book)

if __name__ == "__main__":
    main()
