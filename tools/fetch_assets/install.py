#!/usr/bin/env python3
"""Install chosen candidates: download, re-verify the licence, transcode, place, wire.

Second of the two licence checks. search.py filtered on the Commons licence category;
this one reads the file's own LicenseShortName at download time and refuses anything
that is not CC0 or public domain. A file that fails is dropped, never fixed up.

Each download lands in its own empty directory under downloads/ and is only ever
passed to ffmpeg by path — nothing from Commons is executed or imported.

    python3 -I install.py pets picks-pets.json image

picks-pets.json is {"<term>": "<File:Title.webm>"} — the one candidate chosen by eye.
"""
import json, os, re, subprocess, sys, time, urllib.parse, urllib.request, urllib.error

UA = "OneWordAssetTool/1.0 (offline dictionary asset sourcing)"
API = "https://commons.wikimedia.org/w/api.php"
FREE = ("cc0", "public domain", "pd", "cc pd mark", "no restrictions")
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

def slug(term):
    return re.sub(r"[^a-z0-9]+", "-", term.lower()).strip("-")

def licence_of(title):
    """The file's own licence statement, read fresh. Not the search's word for it."""
    url = API + "?" + urllib.parse.urlencode({
        "action": "query", "format": "json", "titles": title, "prop": "imageinfo",
        "iiprop": "url|extmetadata|size|mime",
        "iiextmetadatafilter": "LicenseShortName|Artist|UsageTerms"})
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for a in range(5):                               # the API throttles too
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                d = json.load(r); break
        except urllib.error.HTTPError as e:
            if e.code != 429 or a == 4: raise
            time.sleep(6 * (a + 1))
    page = next(iter(d["query"]["pages"].values()))
    ii = page["imageinfo"][0]; em = ii.get("extmetadata", {})
    return {"licence": em.get("LicenseShortName", {}).get("value", "?"),
            "artist": re.sub(r"<[^>]+>", "", em.get("Artist", {}).get("value", "")).strip(),
            "url": ii["url"], "descurl": ii.get("descriptionurl", ""),
            "bytes": ii["size"], "mime": ii["mime"]}

def free(licence):
    low = licence.lower()
    return any(f in low for f in FREE) and "by-sa" not in low and "cc by" not in low

def fetch(url, into, tries=5):
    """upload.wikimedia.org throttles separately from the API and will 429 a handful
    of full-size downloads in a row, so this backs off rather than dying mid-book."""
    os.makedirs(into, exist_ok=True)                 # one empty dir per download
    dest = os.path.join(into, os.path.basename(urllib.parse.urlparse(url).path))
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for a in range(tries):
        try:
            with urllib.request.urlopen(req, timeout=180) as r, open(dest, "wb") as f:
                f.write(r.read())
            return dest
        except urllib.error.HTTPError as e:
            if e.code != 429 or a == tries - 1: raise
            time.sleep(6 * (a + 1))
    raise RuntimeError("unreachable")

def transcode(src, dest, seconds=4):
    """720p long edge, no audio, H.264. The clip contract in ClipLoop.swift."""
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                    "-t", str(seconds), "-i", src,
                    "-vf", "scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease",
                    "-an", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
                    dest], check=True, timeout=300)

def resample(src, dest):
    """800px long edge, JPEG q72 — the format the Picture Book's 243 photos set, and
    what check_assets.sh enforces. It draws into a 200-320pt box; bigger is bytes
    shipped to every reader for pixels none of them see."""
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "72",
                    "-Z", "800", src, "--out", dest],
                   check=True, capture_output=True, timeout=120)

def main():
    book, picks_path = sys.argv[1], sys.argv[2]
    kind = sys.argv[3] if len(sys.argv) > 3 else "clip"
    field, folder, ext = (("clip", "Clips", ".mp4") if kind in ("clip", "video")
                          else ("image", "Pictures", ".jpg"))
    picks = json.load(open(picks_path))
    out_dir = os.path.join(ROOT, "OneWord", folder)
    os.makedirs(out_dir, exist_ok=True)
    book_path = os.path.join(ROOT, "OneWord", "Shared", f"{book}.json")
    entries = json.load(open(book_path))
    by_term = {w["term"]: w for w in entries}
    record, refused = {}, []

    for term, title in picks.items():
        if term not in by_term:
            refused.append((term, "no such term in the book")); continue
        meta = licence_of(title)
        if not free(meta["licence"]):
            refused.append((term, f"licence {meta['licence']!r} is not CC0/PD")); continue
        name = f"{book}-{slug(term)}"
        raw = fetch(meta["url"], os.path.join(HERE, "downloads", name))
        dest = os.path.join(out_dir, name + ext)
        (transcode if field == "clip" else resample)(raw, dest)
        by_term[term][field] = name
        meta["file"] = name + ext; meta["title"] = title
        record[term] = meta
        print(f"  {term:20} {meta['licence']:14} {os.path.getsize(dest)/1e3:6.0f} KB  {meta['file']}", flush=True)
        time.sleep(3)

    json.dump(entries, open(book_path, "w"), ensure_ascii=False, indent=1)
    json.dump(record, open(os.path.join(HERE, f"installed-{book}.json"), "w"),
              ensure_ascii=False, indent=1)
    print(f"\n{len(record)} installed, {len(refused)} refused")
    for term, why in refused: print(f"  - {term}: {why}")
    print(f"now run: python3 -I provenance.py {book} {field}")

if __name__ == "__main__":
    main()
