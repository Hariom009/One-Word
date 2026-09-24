#!/bin/sh
# The check for Premium's rules: what a free reader gets, what unlocking opens,
# and what losing Premium does to the reader's pick — the one place a refund
# writes to shared storage. The rules are the whole of Premium.swift; StoreKit
# itself lives in PremiumViewModel and is checked by hand (see the resolved plan).
#
# Compiles the REAL sources. Only AppGroup is shimmed, onto a throwaway suite so
# the run can't touch the app's own storage.
#
#   sh tools/check_premium.sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT=/tmp/onewordpremium
rm -rf "$OUT" && mkdir -p "$OUT"

cat > "$OUT/Shim.swift" <<'SWIFT'
import Foundation

// Stands in for the real AppGroup: a scratch suite, so the check never reads or
// writes the app's actual shared defaults. nonisolated like the real one — the
// flag below makes everything else MainActor.
nonisolated enum AppGroup {
    static let id = "com.hariom.swift.oneword.check"
    static let defaults = UserDefaults(suiteName: id)!
    static let dictionaryKey = "dictionaryID"
    static var dictionaryID: String { defaults.string(forKey: dictionaryKey) ?? "words" }
}
SWIFT

cat > "$OUT/PremiumCheck.swift" <<'SWIFT'
import Foundation

func check(_ condition: Bool, _ what: String) {
    guard condition else { fatalError("FAILED: \(what)") }
    print("  ok  \(what)")
}

/// Stand the reader on a shelf, a few words in, maybe holding a captured word.
func pick(_ id: String, offset: Int = 0, pin: String? = nil) {
    AppGroup.defaults.set(id, forKey: AppGroup.dictionaryKey)
    WordSelectionStore.offset = offset
    WordSelectionStore.pinnedTerm = pin
}

var picked: String? { AppGroup.defaults.string(forKey: AppGroup.dictionaryKey) }

@main
enum Check {
    static func main() {
        let premium = ["emotions", "philosophy", "startup", "idioms", "classical", "urdu", "german"]
        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)

        print("Premium, locked")
        check(!Premium.isUnlocked, "a fresh install is locked")
        check(Premium.allows("words"), "Everyday English is free")
        check(Premium.allows(SavedWords.resource), "Bookmarks is free")
        check(premium.allSatisfy { !Premium.allows($0) }, "every other shelf is locked")
        check(Premium.resolve("urdu") == "words", "a locked shelf resolves to Everyday English")
        check(Premium.resolve("medical") == "words", "so does a dictionary that no longer ships")

        print("\nPremium, unlocked")
        Premium.set(unlocked: true)
        check(Premium.isUnlocked, "unlocking is remembered")
        check(premium.allSatisfy { Premium.allows($0) }, "every shelf is open")
        check(Premium.resolve("urdu") == "urdu", "resolve passes an unlocked shelf through")
        check(!Premium.allows("urdu", unlocked: false), "an explicit flag outranks the stored one")

        print("\nlosing Premium")
        pick("urdu", offset: 3, pin: "ishq")
        Premium.set(unlocked: false)
        check(picked == "words", "a premium pick falls back to Everyday English")
        check(WordSelectionStore.offset == 0, "and the word offset resets with it")
        check(WordSelectionStore.pinnedTerm == nil, "and a pinned capture is dropped")

        pick("words", offset: 3)
        Premium.set(unlocked: false)
        check(picked == "words" && WordSelectionStore.offset == 3,
              "a free pick survives the lock with its offset intact")

        pick(SavedWords.resource)
        Premium.set(unlocked: false)
        check(picked == SavedWords.resource, "Bookmarks survives the lock")

        pick("urdu", offset: 2)
        Premium.set(unlocked: true)
        check(picked == "urdu" && WordSelectionStore.offset == 2, "unlocking never moves the pick")

        AppGroup.defaults.removePersistentDomain(forName: AppGroup.id)
        print("\nall checks passed")
    }
}
SWIFT

# -default-isolation MainActor mirrors the project's SWIFT_DEFAULT_ACTOR_ISOLATION;
# Premium has to hold up as nonisolated under it, because that's what the widget needs.
swiftc -O -default-isolation MainActor -o "$OUT/check" \
    "$ROOT/OneWord/Shared/Word.swift" "$ROOT/OneWord/Shared/WordProvider.swift" \
    "$ROOT/OneWord/Shared/SavedWords.swift" "$ROOT/OneWord/Shared/WordSelectionStore.swift" \
    "$ROOT/OneWord/Shared/Premium.swift" \
    "$OUT/Shim.swift" "$OUT/PremiumCheck.swift"

"$OUT/check"
