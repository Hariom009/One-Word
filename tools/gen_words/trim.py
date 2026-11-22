"""Trim a Wordbook to its best N entries.

Two rules, because the books are not alike. Emotions carries a scraped WordNet
layer (652 entries share a definition with another, 340 share an example, some
still have "- Edmund Burke" hanging off them) — that layer is cut outright.
Corporate Slang has none of it, so there the cut is a ranking, not a rescue.
"""
import json, os, re, collections, sys, hashlib

STEM = re.compile(r'[ \-]')
ATTRIB = re.compile(r'-\s*[A-Z][a-z]+ [A-Z]')

def stem(term):
    return STEM.split(term.lower())[0][:5]

def well_formed(w, shared_def, shared_ex):
    d, e, h = w['definition'].strip(), w['example'].strip(), w['hindi'].strip()
    if not (d and e and h):                      return False   # a half entry is not an entry
    if stem(w['term']) not in e.lower():         return False   # an example that never says the word
    if len(d) < 50:                              return False   # a bare gloss, not a definition
    if ATTRIB.search(d):                         return False   # scrape residue
    if shared_def[d.lower()] > 1:                return False   # WordNet duplicate
    if shared_ex[e.lower()] > 1:                 return False   # recycled example
    if ';' in d and len(d) < 80:                 return False   # "cause to feel shame; hurt the pride of"
    return True

# Everyday English, read from the last commit so a concurrent trim of it can't
# move this selection. A feeling word that is ALSO an everyday word teaches the
# reader nothing and shows up twice in a cross-book search, so it goes to the back.
import subprocess
_everyday = subprocess.run(["git", "show", "HEAD:OneWord/Shared/words.json"],
                           capture_output=True, text=True,
                           cwd=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")).stdout
EVERYDAY = {w['term'].lower() for w in json.loads(_everyday)} if _everyday else set()

# Corporate Slang is a slang book. Idiom and phrase are what it is for; the acronym
# shelf is mostly finance and pharma (MLR, MSL, 8-K) — true of that industry, dead
# weight for everyone else — so it keeps a seat, not a third of the book.
POS_WEIGHT = {'startup': {'acronym': 0.35, 'idiom': 1.6, 'phrase': 1.3}}

def score(w, book):
    d, e, h, t = w['definition'], w['example'], w['hindi'], w['term']
    s = 0.0
    s += 2.0 if 60 <= len(e) <= 150 else (1.0 if 45 <= len(e) <= 190 else 0.0)   # a scene, not a stub
    s += 2.0 if 70 <= len(d) <= 170 else (1.0 if 55 <= len(d) <= 210 else 0.0)   # teaches something
    s += 1.0 if len(h) >= 25 else 0.0                                            # a real Hindi gloss
    s += 0.5 if len(t) <= 24 else 0.0                                            # reads as a headword
    if book == 'emotions' and t.lower() in EVERYDAY:
        s -= 1.5                                                                 # already a word you know
    return s

def trim(entries, keep, book):
    shared_def = collections.Counter(w['definition'].strip().lower() for w in entries)
    shared_ex  = collections.Counter(w['example'].strip().lower() for w in entries if w['example'].strip())
    clean = [w for w in entries if well_formed(w, shared_def, shared_ex)]

    # Proportional by part of speech, so the book keeps its shape instead of
    # collapsing into whichever class happens to score best.
    by_pos = collections.defaultdict(list)
    for w in clean:
        by_pos[w['partOfSpeech']].append(w)
    for pos in by_pos:
        # Ties break on a hash of the term, NOT alphabetically: the score only has a
        # handful of steps, so an alphabetical tiebreak handed the whole book to A-C
        # (500 entries covering five letters). md5, not hash(), which is salted per run.
        by_pos[pos].sort(key=lambda w: (-score(w, book), hashlib.md5(w['term'].encode()).hexdigest()))

    weights = POS_WEIGHT.get(book, {})
    def weight(pos): return weights.get(pos, 1.0)
    # Weighted shares don't sum to one, so normalise against what the weights ask for.
    total = sum(weight(p) * len(g) for p, g in by_pos.items())
    quota = {}
    for pos, group in by_pos.items():
        quota[pos] = min(len(group), round(keep * weight(pos) * len(group) / total))
    # Rounding leaves us a few short or long; settle it on the biggest classes.
    order = sorted(by_pos, key=lambda p: -len(by_pos[p]))
    while sum(quota.values()) < keep:
        for pos in order:
            if sum(quota.values()) >= keep: break
            if quota[pos] < len(by_pos[pos]): quota[pos] += 1
    while sum(quota.values()) > keep:
        for pos in order:
            if sum(quota.values()) <= keep: break
            if quota[pos] > 0: quota[pos] -= 1

    picked = [w for pos in by_pos for w in by_pos[pos][:quota[pos]]]
    picked.sort(key=lambda w: w['term'].lower())
    return clean, picked

if __name__ == '__main__':
    name, keep = sys.argv[1], int(sys.argv[2])
    src = f'OneWord/Shared/{name}.json'
    entries = json.load(open(src))
    clean, picked = trim(entries, keep, name)
    print(f'{name}: {len(entries)} -> well-formed {len(clean)} -> kept {len(picked)}')
    letters = collections.Counter(w['term'][0].lower() for w in picked)
    print('  letters covered:', len(letters), ' biggest:', letters.most_common(3))
    print('  by part of speech:', collections.Counter(w['partOfSpeech'] for w in picked).most_common())
    out = sys.argv[3] if len(sys.argv) > 3 else None
    if out:
        with open(out, 'w', encoding='utf-8') as f:
            json.dump(picked, f, ensure_ascii=False, indent=1)   # matches the books' own format
