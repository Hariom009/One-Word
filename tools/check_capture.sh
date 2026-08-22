#!/bin/sh
# The check for word capture: normalize(), the pin lifecycle, and that a pin
# actually takes the day in WordProvider. Compiles the REAL shared sources —
# only AppGroup is shimmed, onto a throwaway UserDefaults suite so the run
# can't touch the app's own storage.
#
# capture()/lookUp() aren't covered here: they read the bundled JSONs, which a
# standalone script has no bundle for. Everything they depend on is.
#
#   sh tools/check_capture.sh
set -e

SRC="$(cd "$(dirname "$0")/.." && pwd)/OneWord/Shared"
OUT=/tmp/onewordcheck
rm -rf "$OUT" && mkdir -p "$OUT"

cat > "$OUT/Shim.swift" <<'SWIFT'
import Foundation

// Stands in for the real AppGroup: a scratch suite, so the check never reads or
// writes the app's actual shared defaults.
enum AppGroup {
    static let id = "com.hariom.swift.oneword.check"
    static let defaults = UserDefaults(suiteName: id)!
    static let dictionaryKey = "dictionaryID"
    static var dictionaryID: String { defaults.string(forKey: dictionaryKey) ?? "words" }
}
SWIFT

cat > "$OUT/main.swift" <<'SWIFT'
import Foundation

AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)

func check(_ condition: Bool, _ what: String) {
    guard condition else { fatalError("FAILED: \(what)") }
    print("  ok  \(what)")
}

func word(_ term: String) -> Word {
    Word(term: term, partOfSpeech: "noun", hindi: "", definition: "", example: "")
}

print("normalize")
check(SavedWords.normalize("  Ephemeral ") == "ephemeral", "trims and lowercases")
check(SavedWords.normalize("\u{201C}petrichor,\u{201D}") == "petrichor", "strips surrounding punctuation")
check(SavedWords.normalize("of the day") == nil, "rejects a phrase")
check(SavedWords.normalize("   ") == nil, "rejects blank")
check(SavedWords.normalize("...") == nil, "rejects punctuation only")

print("firstSense")
// The exact blob macOS returned for "ephemeral" — headword, syllabification,
// pronunciation, two senses, derivatives and etymology, all run together.
let ephemeral = """
ephemeral e\u{00B7}phem\u{00B7}er\u{00B7}al | \u{0259}\u{02C8}fem(\u{0259})r\u{0259}l | adjective lasting for a very \
short time: fashions are ephemeral. \u{2022} (chiefly of plants) having a very short life cycle: chickweed is an \
ephemeral weed, producing several generations in one season. noun an ephemeral plant: ephemerals avoid the periods \
of drought as seeds. DERIVATIVES ephemerality | \u{0259}\u{02CC}fem(\u{0259})\u{02C8}ral\u{0259}d\u{0113} | noun \
ORIGIN late 16th century: from Greek eph\u{0113}meros (see ephemera) + -al.
"""
let sense = SavedWords.firstSense(ephemeral, term: "ephemeral")
check(sense.partOfSpeech == "adjective", "pulls the part of speech")
check(sense.definition == "lasting for a very short time", "keeps only the first sense")
check(sense.example == "fashions are ephemeral", "recovers the example after the colon")

let noPron = SavedWords.firstSense("gubbins noun a gadget: a useful gubbins.", term: "gubbins")
check(noPron.partOfSpeech == "noun", "works without a pronunciation block")
check(noPron.definition == "a gadget", "strips the headword when there's no pronunciation")

let bare = SavedWords.firstSense("zzz something odd", term: "zzz")
check(bare.partOfSpeech == "", "no part of speech is not a failure")
check(bare.definition == "something odd", "keeps the text it can't classify")

let long = SavedWords.firstSense("x | y | noun " + String(repeating: "ab ", count: 300), term: "x")
check(long.definition.count <= 301, "definitions stay card-sized")
check(long.definition.hasSuffix("\u{2026}"), "and say when they were cut")

print("pin lifecycle")
let today = SavedWord(word: word("trade"), savedAt: Date())
let yesterday = SavedWord(word: word("global"), savedAt: Date().addingTimeInterval(-86_400))

SavedWords.all = [today]
WordStore.pinnedTerm = "trade"
check(SavedWords.pinned?.term == "trade", "a word pinned today holds the day")

WordStore.advance()
check(SavedWords.pinned == nil, "New Word clears the pin (so it isn't a no-op)")

SavedWords.all = [yesterday]
WordStore.pinnedTerm = "global"
check(SavedWords.pinned == nil, "a pin from yesterday has expired")

WordStore.pinnedTerm = "never-saved"
SavedWords.all = [today]
check(SavedWords.pinned == nil, "a pin with no matching saved word resolves to nil")

print("provider")
let list = (1...50).map { word("w\($0)") }
let provider = WordProvider(words: list, seed: 99)
let day = Date(timeIntervalSinceReferenceDate: 800_000_000)

let plain = provider.word(for: day, offset: 0)
check(provider.word(for: day, offset: 0).term == plain.term, "same day+offset is stable")
check(provider.word(for: day, offset: 0, pinned: nil).term == plain.term, "a nil pin changes nothing")
check(provider.word(for: day, offset: 0, pinned: word("caught")).term == "caught", "a pin takes the day")
check(provider.word(for: day, offset: 7, pinned: word("caught")).term == "caught", "a pin beats the offset too")

let tomorrow = day.addingTimeInterval(86_400)
check(provider.word(for: tomorrow, offset: 0).term != plain.term, "the day still advances without a pin")

AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)
print("\nall checks passed")
SWIFT

swiftc -O -o "$OUT/check" \
    "$SRC/Word.swift" "$SRC/WordProvider.swift" "$SRC/WordStore.swift" \
    "$SRC/SavedWords.swift" "$OUT/Shim.swift" "$OUT/main.swift"

"$OUT/check"
