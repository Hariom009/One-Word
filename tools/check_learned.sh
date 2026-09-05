#!/bin/sh
# The check for learned-word tracking, bookmarking and the peek: LearnedWords'
# per-dictionary bookkeeping and its resolution back to full words, that a
# bookmark doesn't hijack today's word, and that "New Word" shows another word
# and then puts the day's word back — including the case that made it a bug, a
# peek left running while the reader moves to a different day.
#
# Compiles the REAL sources. Only AppGroup is shimmed, onto a throwaway suite so
# the run can't touch the app's own storage; words.json is copied next to the
# binary so Bundle.main can find it the way the app's bundle does.
#
#   sh tools/check_learned.sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT=/tmp/onewordlearned
rm -rf "$OUT" && mkdir -p "$OUT"
cp "$ROOT/OneWord/Shared/"*.json "$OUT/"

cat > "$OUT/Shim.swift" <<'SWIFT'
import Foundation

// Stands in for the real AppGroup: a scratch suite, so the check never reads or
// writes the app's actual shared defaults.
nonisolated enum AppGroup {
    static let id = "com.hariom.swift.oneword.check"
    static let defaults = UserDefaults(suiteName: id)!
    static let dictionaryKey = "dictionaryID"
    static var dictionaryID: String { defaults.string(forKey: dictionaryKey) ?? "words" }
}
SWIFT

cat > "$OUT/LearnedCheck.swift" <<'SWIFT'
import Foundation

func check(_ condition: Bool, _ what: String) {
    guard condition else { fatalError("FAILED: \(what)") }
    print("  ok  \(what)")
}

func word(_ term: String) -> Word {
    Word(term: term, partOfSpeech: "noun", hindi: "", definition: "", example: "")
}

@main
enum Check {
    static func main() async {
        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)

        print("LearnedWords")
        check(LearnedWords.total == 0, "starts empty")

        LearnedWords.record(word("petrichor"), in: "words")
        check(LearnedWords.count(in: "words") == 1, "a word is recorded")
        check(LearnedWords.total == 1, "and counted in the total")

        LearnedWords.record(word("petrichor"), in: "words")
        check(LearnedWords.count(in: "words") == 1, "re-reading the same word doesn't double-count")

        LearnedWords.record(word("petrichor"), in: "emotions")
        check(LearnedWords.count(in: "words") == 1, "the same word elsewhere leaves the first shelf alone")
        check(LearnedWords.count(in: "emotions") == 1, "and lands on the second")
        check(LearnedWords.total == 2, "shelves add up")

        LearnedWords.record(SavedWords.placeholder, in: "saved")
        check(LearnedWords.count(in: "saved") == 0, "the My Words placeholder is not a learned word")

        check(LearnedWords.count(in: "philosophy") == 0, "an unread shelf reads zero, not nil-crash")

        // Survives a round trip through defaults — the profile reads it back cold.
        check(LearnedWords.all["words"]?.keys.sorted() == ["petrichor"], "decodes back to what was written")
        check(LearnedWords.all["words"]?["petrichor"] != nil, "stamped with when it was seen")

        print("\npeek")
        let day = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let model = WordViewModel(wordbook: .everydayEnglish)
        model.refresh(for: day)
        let today = model.word.term
        check(!model.isPeeking, "settled to start with")

        model.shuffle(for: day)
        check(model.word.term != today, "a peek shows another word")
        check(model.isPeeking, "and says so")
        let first = model.word.term
        model.shuffle(for: day)
        check(model.word.term != first, "peeking again moves on again")
        check(WordSelectionStore.offset == 0, "a peek never touches the shared offset the widget reads")

        try? await Task.sleep(for: WordViewModel.peekDuration + .seconds(1))
        check(model.word.term == today, "the day's word comes back on its own")
        check(!model.isPeeking, "and the peek flag clears")

        // The bug this guards: a peek left running while the reader moves to
        // another day used to fire late and yank the old day's word back.
        let otherDay = day.addingTimeInterval(86_400 * 3)
        model.shuffle(for: day)
        model.refresh(for: otherDay)
        let otherWord = model.word.term
        check(otherWord != today, "a different day is a different word")
        try? await Task.sleep(for: WordViewModel.peekDuration + .seconds(1))
        check(model.word.term == otherWord, "a pending peek doesn't yank the old day back")

        print("\nbookmarks")
        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)
        let dict = WordProvider(resource: "words").allWords
        // capture() rejects anything that isn't a bare word, so pick two of those.
        let plain = dict.filter { $0.term.allSatisfy(\.isLetter) }
        check(plain.count >= 2, "words.json has bare single-word terms to test with")
        let a = plain[0], b = plain[1]

        check(!SavedWords.contains(a), "nothing bookmarked to start")
        check(SavedWords.toggle(a), "bookmarking reports the new state")
        check(SavedWords.contains(a), "and the word is in")
        check(SavedWords.all.count == 1, "exactly once")
        check(WordSelectionStore.pinnedTerm == nil, "bookmarking does NOT hijack today's word")

        check(!SavedWords.toggle(a), "toggling again reports off")
        check(!SavedWords.contains(a), "and takes the word back out")
        check(SavedWords.all.isEmpty, "leaving nothing behind")

        check(!SavedWords.toggle(SavedWords.placeholder), "the placeholder can't be bookmarked")
        check(SavedWords.all.isEmpty, "and never gets stored")

        // The bug this guards: un-bookmarking a captured word used to leave
        // pinnedTerm pointing at a word no longer in the list.
        SavedWords.capture(b.term)
        check(WordSelectionStore.pinnedTerm == b.term, "a capture pins its word")
        SavedWords.toggle(b)
        check(WordSelectionStore.pinnedTerm == nil, "un-bookmarking the pinned word clears the pin")
        check(SavedWords.pinned == nil, "so today's word falls back to the dictionary's")

        print("\ntimestamps")
        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)
        let before = Date()
        LearnedWords.record(word("petrichor"), in: "words")
        let stamp = LearnedWords.all["words"]!["petrichor"]!
        check(stamp >= before && stamp <= Date(), "a sighting is stamped now")

        try? await Task.sleep(for: .milliseconds(20))
        LearnedWords.record(word("petrichor"), in: "words")
        check(LearnedWords.all["words"]!["petrichor"] == stamp,
              "re-reading keeps the FIRST sighting, not the latest")

        // The shape before the log kept times: dictionary id -> array of terms.
        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)
        let legacy = try! JSONEncoder().encode(["words": Set(["petrichor", "sonder"])])
        AppGroup.defaults.set(legacy, forKey: "learnedWords")
        check(LearnedWords.count(in: "words") == 2, "words learned before timestamps still count")
        check(LearnedWords.all["words"]!["sonder"] == .distantPast, "stamped as unknown, not as now")
        check(!LearnedWord(word: word("sonder"), shelf: "words", seenAt: .distantPast).isTimestamped,
              "and the log knows not to print a time for it")

        print("\nlearned log")
        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)
        check(LearnedWords.log.isEmpty, "nothing read, nothing logged")

        LearnedWords.record(a, in: "words")
        try? await Task.sleep(for: .milliseconds(20))
        LearnedWords.record(b, in: "words")
        let logged = LearnedWords.log
        check(logged.count == 2, "sightings resolve back to full words")
        check(logged.first?.word.term == b.term, "newest first")
        check(logged.contains { $0.word.definition == a.definition && $0.shelf == "words" },
              "carrying the definition and the shelf they were read in")

        LearnedWords.record(word("ghost"), in: "a-shelf-that-no-longer-ships")
        check(LearnedWords.log.count == 2, "a removed shelf is skipped, not fatalError'd")

        // Same word on two shelves is two sightings — the log shows both, and
        // LearnedWord.id folds in the shelf so the List doesn't see a duplicate.
        let emotions = Set(WordProvider(resource: "emotions").allWords.map(\.term))
        if let shared = dict.first(where: { emotions.contains($0.term) }) {
            LearnedWords.record(shared, in: "words")
            LearnedWords.record(shared, in: "emotions")
            let both = LearnedWords.log.filter { $0.word.term == shared.term }
            check(both.count == 2, "a word met on two shelves logs both sightings")
            check(Set(both.map(\.id)).count == 2, "with ids the List can tell apart")
        } else {
            print("  --  no term shared by words and emotions; two-shelf case not exercised")
        }

        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)
        print("\nall checks passed")
    }
}
SWIFT

# -default-isolation MainActor mirrors the project's SWIFT_DEFAULT_ACTOR_ISOLATION;
# without it WordViewModel compiles nonisolated and the peek's Task would not hop
# back to the actor the app actually runs it on.
swiftc -O -default-isolation MainActor -o "$OUT/check" \
    "$ROOT/OneWord/Shared/Word.swift" "$ROOT/OneWord/Shared/WordProvider.swift" \
    "$ROOT/OneWord/Shared/SavedWords.swift" "$ROOT/OneWord/Shared/WordSelectionStore.swift" \
    "$ROOT/OneWord/Shared/Theme.swift" "$ROOT/OneWord/Models/Wordbook.swift" \
    "$ROOT/OneWord/Models/LearnedWords.swift" "$ROOT/OneWord/ViewModels/WordViewModel.swift" \
    "$OUT/Shim.swift" "$OUT/LearnedCheck.swift"

"$OUT/check"
