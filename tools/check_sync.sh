#!/bin/sh
# The check for iCloud sync's merge rules (CloudSync.swift): learned words union
# to the earliest sighting, a bookmark's latest event wins — tombstones included,
# so a delete on one device isn't resurrected by the other — and merging is
# idempotent, which is what stops the didChange → sync loop. Also that un-
# bookmarking leaves the tombstone the merge depends on.
#
# The iCloud store itself isn't exercised: a bare binary has no entitlement.
#
# Compiles the REAL sources. Only AppGroup is shimmed, onto a throwaway suite so
# the run can't touch the app's own storage.
#
#   sh tools/check_sync.sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT=/tmp/onewordsync
rm -rf "$OUT" && mkdir -p "$OUT"

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

cat > "$OUT/SyncCheck.swift" <<'SWIFT'
import Foundation

func check(_ condition: Bool, _ what: String) {
    guard condition else { fatalError("FAILED: \(what)") }
    print("  ok  \(what)")
}

func word(_ term: String) -> Word {
    Word(term: term, partOfSpeech: "noun", hindi: "", definition: "", example: "")
}

func at(_ seconds: Double) -> Date { Date(timeIntervalSinceReferenceDate: 800_000_000 + seconds) }

func saved(_ term: String, _ seconds: Double) -> SavedWord { SavedWord(word: word(term), savedAt: at(seconds)) }

typealias Bookmarks = CloudSync.Bookmarks

@main
enum Check {
    static func main() {
        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)

        print("learned")
        let mac = ["words": ["petrichor": at(10), "sonder": at(5)]]
        let phone = ["words": ["petrichor": at(3)], "emotions": ["hiraeth": at(7)]]
        let learned = CloudSync.merge(mac, phone)
        check(learned["words"]?["petrichor"] == at(3), "a term on both keeps the EARLIEST sighting")
        check(learned["words"]?["sonder"] == at(5), "a term on one side survives")
        check(learned["emotions"]?["hiraeth"] == at(7), "a shelf on one side survives")
        check(learned == CloudSync.merge(phone, mac), "order doesn't matter")
        check(CloudSync.merge(learned, learned) == learned, "merging with itself changes nothing")
        check(CloudSync.merge(learned, phone) == learned, "re-merging a side already in changes nothing")
        check(CloudSync.merge(mac, [:]) == mac, "an empty cloud leaves local as it was")

        print("\nbookmarks")
        let kept = Bookmarks(saved: [saved("a", 1), saved("b", 2)], removed: [:])
        let unsaved = Bookmarks(saved: [], removed: ["a": at(5)])
        let afterDelete = CloudSync.merge(kept, unsaved)
        check(afterDelete.saved.map(\.word.term) == ["b"], "a tombstone newer than a save removes it")
        check(afterDelete.removed["a"] == at(5), "and the tombstone is kept to say so")

        let resaved = Bookmarks(saved: [saved("a", 9)], removed: [:])
        let afterResave = CloudSync.merge(afterDelete, resaved)
        check(afterResave.saved.map(\.word.term) == ["b", "a"], "a save newer than a tombstone keeps it, newest last")
        check(afterResave.removed.isEmpty, "and drops the tombstone it beat")

        let tie = CloudSync.merge(Bookmarks(saved: [saved("c", 4)], removed: [:]),
                                  Bookmarks(saved: [], removed: ["c": at(4)]))
        check(tie.saved.isEmpty, "an un-save at the same instant as the save wins")

        let edited = CloudSync.merge(Bookmarks(saved: [saved("a", 1)], removed: [:]), resaved)
        check(edited.saved.count == 1 && edited.saved[0].savedAt == at(9), "a term saved on both keeps the latest save, once")

        let mixed = CloudSync.merge(kept, Bookmarks(saved: [saved("d", 3)], removed: ["b": at(6), "a": at(0)]))
        check(mixed.saved.map(\.word.term) == ["a", "d"], "each term is decided on its own")
        check(mixed == CloudSync.merge(Bookmarks(saved: [saved("d", 3)], removed: ["b": at(6), "a": at(0)]), kept),
              "order doesn't matter")
        check(CloudSync.merge(mixed, mixed) == mixed, "merging with itself changes nothing")
        check(CloudSync.merge(mixed, kept) == mixed, "re-merging a side already in changes nothing")

        print("\ntombstones")
        let a = word("ephemeral")
        SavedWords.toggle(a)
        check(SavedWords.removed.isEmpty, "bookmarking leaves no tombstone")
        let before = Date()
        SavedWords.toggle(a)
        check((SavedWords.removed[a.term] ?? .distantPast) >= before, "un-bookmarking records when")
        let local = Bookmarks(saved: SavedWords.all, removed: SavedWords.removed)
        let stale = Bookmarks(saved: [SavedWord(word: a, savedAt: before.addingTimeInterval(-60))], removed: [:])
        check(CloudSync.merge(local, stale).saved.isEmpty, "so the other device's older copy doesn't bring it back")

        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)
        print("\nall checks passed")
    }
}
SWIFT

# -default-isolation MainActor mirrors the project's SWIFT_DEFAULT_ACTOR_ISOLATION.
swiftc -O -default-isolation MainActor -o "$OUT/check" \
    "$ROOT/OneWord/Shared/Word.swift" "$ROOT/OneWord/Shared/WordProvider.swift" \
    "$ROOT/OneWord/Shared/SavedWords.swift" "$ROOT/OneWord/Shared/WordSelectionStore.swift" \
    "$ROOT/OneWord/Shared/Theme.swift" "$ROOT/OneWord/Models/Wordbook.swift" \
    "$ROOT/OneWord/Models/LearnedWords.swift" "$ROOT/OneWord/Models/CloudSync.swift" \
    "$OUT/Shim.swift" "$OUT/SyncCheck.swift"

"$OUT/check"
