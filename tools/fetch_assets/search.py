#!/usr/bin/env python3
"""Find freely-licensed candidate media on Wikimedia Commons for a book's terms.

Licence is filtered IN THE QUERY, never after: a file that is not CC0 or public
domain never reaches the shortlist, so nobody can pick one by accident. Same rule
the Picture Book's 243 photos were pulled under — see
Docs/06_Misc/PICTURES_IMAGE_SOURCES.md. The LicenseShortName on each file is
checked again at install time, so every asset clears two independent checks.

Writes candidates.json. Downloads nothing.

    python3 -I search.py pets video
"""
import json, sys, time, urllib.parse, urllib.request, os

API = "https://commons.wikimedia.org/w/api.php"
FAILURES = []
# A generic client name on purpose: nothing about the user or the project goes to Commons.
UA = "OneWordAssetTool/1.0 (offline dictionary asset sourcing)"

# Commons licence categories that need no attribution and carry no share-alike
# obligation. CC BY and CC BY-SA are deliberately absent: they are free, but they
# put an attribution burden inside a shipped app that we are not set up to honour.
# Trimmed to the two that actually return animal media. Every extra category is a
# round trip per term, and Commons rate-limits hard: the first sweep over this book
# spent most of its queries on HTTP 429 and reported a yield that was pure noise.
FREE_CATEGORIES = ["CC-Zero", "PD-self"]
# No application/ogg: it is an AUDIO mime, and letting it in made "mew" look like it
# had 40 video candidates when they were cat pronunciations and music tracks.
MIMES = {"video": ["video/webm", "video/ogg"], "image": ["image/jpeg"]}

def gerund(word):
    if word.endswith("ing"): return word
    if word.endswith("e"):   return word[:-1] + "ing"
    return word + "ing"

# Commons titles media by SUBJECT, not by behaviour — which is why video is hopeless
# here ("My cat Mittens" is a purring cat nobody can find). Photos are the exception:
# "A large chained dog howling", "Cat yawning - DSC00577". So the query has to be the
# phrase a human would caption a photo with, animal first and the verb as a gerund.
# Measured: "dog howling" finds the husky, "howl dog" finds nothing.
def query_terms(term, pos):
    animal = "cat" if "cat" in pos else "dog"
    head = term.split()[-1]                      # "alarm bark" -> "bark"
    return [f"{animal} {gerund(head)}", f"{gerund(head)} {animal}"]

def api(params, tries=5):
    """Commons rate-limits aggressively. Back off and retry rather than silently
    reporting an empty result, which is what made the first sweep's numbers lies."""
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 429 or attempt == tries - 1: raise
            time.sleep(4 * (attempt + 1))
    raise RuntimeError("unreachable")

def search(text, mimes, limit=8):
    hits = []
    for cat in FREE_CATEGORIES:
        for mime in mimes:
            try:
                d = api({"action": "query", "format": "json", "generator": "search",
                         "gsrsearch": f"incategory:{cat} filemime:{mime} {text}",
                         "gsrnamespace": 6, "gsrlimit": limit,
                         "prop": "imageinfo",
                         "iiprop": "url|extmetadata|size|mime|mediatype",
                         "iiextmetadatafilter": "LicenseShortName|Artist|UsageTerms"})
            except Exception as e:
                # Loud on purpose. A swallowed failure here reads as "no candidate".
                print(f"    ! {cat}/{mime} {text!r}: {e}", file=sys.stderr)
                FAILURES.append(f"{cat}/{mime} {text!r}: {e}")
                continue
            for p in d.get("query", {}).get("pages", {}).values():
                ii = p["imageinfo"][0]; em = ii.get("extmetadata", {})
                hits.append({"title": p["title"], "url": ii["url"],
                             "licence": em.get("LicenseShortName", {}).get("value", "?"),
                             "artist": em.get("Artist", {}).get("value", ""),
                             "bytes": ii["size"], "mime": ii["mime"],
                             "descurl": ii.get("descriptionurl", ""),
                             "category": cat, "query": text})
            time.sleep(1.5)                       # be a polite client
    return hits

def main():
    book, kind = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "video")
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    entries = json.load(open(os.path.join(root, "OneWord", "Shared", f"{book}.json")))
    found, empty = {}, []
    for w in entries:
        seen, hits = set(), []
        for q in query_terms(w["term"], w.get("partOfSpeech", "")):
            for h in search(q, MIMES[kind]):
                if h["title"] in seen: continue
                seen.add(h["title"]); hits.append(h)
        found[w["term"]] = hits
        if not hits: empty.append(w["term"])
        print(f"  {w['term']:20} {len(hits):3} candidates")
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), f"candidates-{book}-{kind}.json")
    json.dump(found, open(out, "w"), ensure_ascii=False, indent=1)
    if FAILURES:
        print(f"\n!! {len(FAILURES)} queries FAILED — the coverage below is a floor, not a "
              f"measurement. Re-run before trusting it.")
    covered = len(entries) - len(empty)
    print(f"\n{covered}/{len(entries)} terms have at least one freely-licensed candidate "
          f"({100*covered//len(entries)}%)")
    if empty: print("no candidate:", ", ".join(empty))
    print("written:", out)

if __name__ == "__main__":
    main()
