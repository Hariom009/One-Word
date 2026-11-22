import json, random
from nltk.corpus import wordnet as wn
from wordfreq import zipf_frequency
POS={'n':'noun','v':'verb','a':'adjective','s':'adjective','r':'adverb'}
# skip crude/sensitive glosses — keep a daily widget wholesome
BAD=("genital","sexual","penis","vagina","obscene","vulgar","offensive term",
     "racial","ethnic slur","slang","buttock","copulat","masturbat","erotic","anus")
LO,HI=3.0,3.6   # zipf band: real vocabulary only. HI was 5.6 and let in the
                # spoken-tongue words (cat 4.8, give 5.7, health, music) — a
                # word-a-day must not serve a word you already use daily.
cands=set()
for syn in wn.all_synsets():
    if syn.pos() not in POS: continue
    for lem in syn.lemmas():
        n=lem.name()
        if n.isalpha() and n.islower() and 4<=len(n)<=14:
            cands.add(n)
# drop inflections of easy words: "freeing"/"banning"/"washed" are not vocabulary
# even when the inflected form itself is rare. ponytail: suffix-strip, not a lemmatizer.
def easy_inflection(t):
    o=[]
    if t.endswith('ing'): o+=[t[:-3], t[:-3]+'e', t[:-4]]
    if t.endswith('ed'):  o+=[t[:-2], t[:-1], t[:-3]]
    if t.endswith('s') and not t.endswith('ss'): o+=[t[:-1]]+([t[:-2]] if t.endswith('es') else [])
    if t.endswith('ly'):  o+=[t[:-2]]
    return any(zipf_frequency(b,'en')>=4.3 for b in o if len(b)>=3)

rows={}
for w in cands:
    if easy_inflection(w): continue
    z=zipf_frequency(w,'en')
    if not (LO<=z<=HI): continue
    syn=wn.synsets(w)[0]                      # dominant sense
    d=syn.definition()
    if any(b in d for b in BAD): continue
    ex=syn.examples()[0] if syn.examples() else ""
    rows[w]=(POS[syn.pos()],d,ex,z)
allw=list(rows)
print(f"in-band candidates: {len(allw)}")
TARGET=12000   # the 3.0-3.6 band yields ~5.6k, so this no longer bites
sel=allw if len(allw)<=TARGET else random.Random(7).sample(allw,TARGET)
random.Random(42).shuffle(sel)
with_ex=sum(1 for w in sel if rows[w][2])
print(f"selected: {len(sel)} | with example: {with_ex} ({100*with_ex//len(sel)}%)")
print("=== random 18 (quality eyeball) ===")
for w in random.Random(3).sample(sel,18): print(f"  {w:14} {rows[w][0]:9} z={rows[w][3]:.1f}  {rows[w][1][:52]}")
json.dump([{"term":w,"pos":rows[w][0],"def":rows[w][1],"ex":rows[w][2]} for w in sel],
          open("candidates.json","w"), ensure_ascii=False)
print("wrote candidates.json")
