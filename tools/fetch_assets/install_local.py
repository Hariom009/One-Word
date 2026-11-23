#!/usr/bin/env python3
"""Install locally-made images into a book — the generated path, not the Commons one.

install.py sources from Commons and verifies a licence. These are made for us, so
there is no licence to check and no author to credit; what the provenance table
records instead is the model and the date, because the question worth being able to
answer about any shipped asset is "where did this come from".

Files are matched to terms by filename (`pets-alarm-bark.webp` -> "alarm bark"), or
by a map.json in the same folder ({"1.webp": "alarm bark"}) when the generator named
them its own way.

    python3 -I install_local.py pets ~/Downloads/pets-images "GPT Image"
"""
import json, os, re, subprocess, sys, tempfile, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
EXTS = (".webp", ".png", ".jpg", ".jpeg", ".heic", ".tif", ".tiff")

# Generators stamp their own mark into the bottom-right corner. Measured on this
# tool's output: about 25px tall at the very bottom edge of an 800px-high render,
# so 6% clears it with roughly twice the margin it needs at any source size.
#
# Trimming the bottom costs nothing here on purpose: the prompt docs put the subject
# in the upper two thirds and keep the lower third plain, because the headword prints
# over it. So this takes the strip the layout was already going to cover.
#
# Applied to every generated file, clean or not — a per-image check is a detector that
# can be wrong, and mine was: a brightness threshold missed the mark on five of seven
# images whose corner happened to be light, and flagged two that were clean.
TRIM_BOTTOM = 0.06

def slug(term):
    return re.sub(r"[^a-z0-9]+", "-", term.lower()).strip("-")

def main():
    book, folder = sys.argv[1], os.path.expanduser(sys.argv[2])
    model = sys.argv[3] if len(sys.argv) > 3 else "unspecified"
    book_path = os.path.join(ROOT, "OneWord", "Shared", f"{book}.json")
    entries = json.load(open(book_path))
    by_slug = {slug(w["term"]): w for w in entries}

    mapping = {}
    map_path = os.path.join(folder, "map.json")
    if os.path.exists(map_path):
        mapping = {k: slug(v) for k, v in json.load(open(map_path)).items()}

    out_dir = os.path.join(ROOT, "OneWord", "Pictures")
    os.makedirs(out_dir, exist_ok=True)
    rec_path = os.path.join(HERE, f"generated-{book}.json")
    record = json.load(open(rec_path)) if os.path.exists(rec_path) else {}
    done, skipped = 0, []

    for f in sorted(os.listdir(folder)):
        if not f.lower().endswith(EXTS): continue
        stem = os.path.splitext(f)[0]
        s = mapping.get(f) or (stem[len(book) + 1:] if stem.startswith(book + "-") else None)
        if not s or s not in by_slug:
            skipped.append(f"{f} (no term — name it {book}-<slug> or add it to map.json)")
            continue
        name = f"{book}-{s}"
        dest = os.path.join(out_dir, f"{name}.jpg")
        src = os.path.join(folder, f)
        # Crop first, downsample second: trimming after the resize would throw away
        # detail we had and then crop what is left.
        cropped = os.path.join(tempfile.gettempdir(), f"{name}-trim.png")
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", src,
                        "-vf", f"crop=iw:ih*{1 - TRIM_BOTTOM}:0:0", cropped],
                       check=True, capture_output=True, timeout=180)
        # 800px long edge, q72 — the Picture Book's format, what check_assets enforces.
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "72",
                        "-Z", "800", cropped, "--out", dest],
                       check=True, capture_output=True, timeout=120)
        os.remove(cropped)
        by_slug[s]["image"] = name
        record[by_slug[s]["term"]] = {"file": f"{name}.jpg", "model": model,
                                      "made": datetime.date.today().isoformat(),
                                      "source_file": f,
                                      "trimmed": f"{int(TRIM_BOTTOM*100)}% off the bottom"}
        done += 1
        print(f"  {by_slug[s]['term']:20} {os.path.getsize(dest)/1e3:6.0f} KB  {name}.jpg")

    json.dump(entries, open(book_path, "w"), ensure_ascii=False, indent=1)
    json.dump(record, open(rec_path, "w"), ensure_ascii=False, indent=1)
    illus = sum(1 for w in entries if w.get("image"))
    print(f"\n{done} installed — {book} is now {illus}/{len(entries)} illustrated")
    for s in skipped: print("  skipped:", s)

if __name__ == "__main__":
    main()
