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
import json, os, re, subprocess, sys, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
EXTS = (".webp", ".png", ".jpg", ".jpeg", ".heic", ".tif", ".tiff")

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
        # 800px long edge, q72 — the Picture Book's format, what check_assets enforces.
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "72",
                        "-Z", "800", os.path.join(folder, f), "--out", dest],
                       check=True, capture_output=True, timeout=120)
        by_slug[s]["image"] = name
        record[by_slug[s]["term"]] = {"file": f"{name}.jpg", "model": model,
                                      "made": datetime.date.today().isoformat(),
                                      "source_file": f}
        done += 1
        print(f"  {by_slug[s]['term']:20} {os.path.getsize(dest)/1e3:6.0f} KB  {name}.jpg")

    json.dump(entries, open(book_path, "w"), ensure_ascii=False, indent=1)
    json.dump(record, open(rec_path, "w"), ensure_ascii=False, indent=1)
    illus = sum(1 for w in entries if w.get("image"))
    print(f"\n{done} installed — {book} is now {illus}/{len(entries)} illustrated")
    for s in skipped: print("  skipped:", s)

if __name__ == "__main__":
    main()
