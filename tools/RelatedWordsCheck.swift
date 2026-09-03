//
//  RelatedWordsCheck.swift — standalone self-check for the related-words index.
//  Not a target member; compiles the real source. Run: tools/check_related.sh
//
//  precondition, not assert — the script compiles with -O, where assert is a no-op.
//

import Foundation

let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().appendingPathComponent("OneWord/Shared")

func load(_ id: String) -> [Word] {
    let data = try! Data(contentsOf: dir.appendingPathComponent("\(id).json"))
    return try! JSONDecoder().decode([Word].self, from: data)
}

@main
enum Check {
    static func main() {
        let books = ["words", "emotions", "medical", "philosophy", "character",
                     "eloquence", "curiosities", "startup", "idioms"]
        var indexes: [String: (words: [Word], index: RelatedWordsIndex)] = [:]

        // 1. Coverage ≥99% per book — a reworded definition can silently drop entries.
        for id in books {
            let words = load(id)
            guard let index = RelatedWordsIndex(words: words) else {
                fatalError("NLEmbedding unavailable — cannot check")
            }
            precondition(Double(index.count) >= 0.99 * Double(words.count),
                         "\(id): coverage \(index.count)/\(words.count)")
            indexes[id] = (words, index)
        }

        func nearest(_ book: String, _ term: String) -> [String] {
            let (words, index) = indexes[book]!
            guard let word = words.first(where: { $0.term == term }) else {
                fatalError("\(book) has no term \(term)")
            }
            return index.nearest(to: word).map(\.term)
        }

        // 2. Known pairs still rank in the top three — melancholy → wistful is the
        //    semantic regression pin. The startup check is the proof multi-word
        //    terms work at all (they have no word vector of their own): the query
        //    AND at least one result must be multi-word. Measured top-3 under the
        //    canonical tokenizer: tech lead, lifestyle business, maker time.
        precondition(nearest("emotions", "melancholy").contains("wistful"),
                     "melancholy no longer finds wistful")
        let tenX = nearest("startup", "10x engineer")
        precondition(!tenX.isEmpty && tenX.contains { $0.contains(" ") },
                     "10x engineer found \(tenX)")

        // 3. The small books return REAL results (measured r4, operator-ruled) — not [].
        precondition(nearest("character", "affable").contains("amiable"),
                     "affable no longer finds amiable")
        precondition(nearest("eloquence", "eloquent").contains("rhetoric"),
                     "eloquent no longer finds rhetoric")
        for id in ["character", "eloquence", "curiosities"] {
            let (words, index) = indexes[id]!
            let served = words.filter { !index.nearest(to: $0).isEmpty }.count
            // Measured 20/20 per book — `served > 0` would pass on 1/20 and hide
            // a floor mistune or a broken tokenizer.
            precondition(served == words.count, "\(id): only \(served)/\(words.count) served")
        }

        // 4. The floor EXCLUDES. Every other assertion here tests inclusion, and
        //    removing a filter only adds candidates — verified: with the floor
        //    deleted outright, this whole script still exited 0.
        for (id, (words, index)) in indexes {
            for word in words.prefix(400) {
                for hit in index.nearestScored(to: word) {
                    precondition(hit.score >= RelatedWordsIndex.similarityFloor,
                                 "\(id): \(word.term) -> \(hit.word.term) scored \(hit.score), below the floor")
                }
            }
        }

        // 5. A short query term must not receive its own inflections. Before the
        //    sameRoot fix, `joy` returned joyfulness and joyousness: a <=3 char
        //    term can never share a 4-char stem with its own suffixed form.
        for id in indexes.keys {
            let (words, index) = indexes[id]!
            for word in words where word.term.count <= 4 {
                let canon = word.term.lowercased()
                for hit in index.nearest(to: word) {
                    let other = hit.term.lowercased()
                    precondition(!other.hasPrefix(canon) && !canon.hasPrefix(other),
                                 "\(id): \(word.term) -> \(hit.term) is its own inflection")
                }
            }
        }

        // 6. No two results share a root (sampled across the big book).
        let (everyday, everydayIndex) = indexes["words"]!
        for i in stride(from: 0, to: everyday.count, by: 250) {
            let stems = everydayIndex.nearest(to: everyday[i])
                .map { String($0.term.lowercased().prefix(4)) }
            precondition(Set(stems).count == stems.count,
                         "stem dupes for \(everyday[i].term): \(stems)")
        }

        // 7. The captured-word path: empty definition + unknown term → [], not a crash.
        let ghost = Word(term: "zzgibberishzz", partOfSpeech: "", hindi: "",
                         definition: "", example: "")
        precondition(everydayIndex.nearest(to: ghost).isEmpty, "ghost word got results")
        precondition(everydayIndex.nearest(to: SavedWords.placeholder).isEmpty,
                     "placeholder got results")

        // 8. Case identity: a lowercased capture never gets its uppercase twin back
        //    as "related" (captures are lowercased; startup has 175 mixed-case terms).
        let (startupWords, startupIndex) = indexes["startup"]!
        let mixed = startupWords.first { $0.term != $0.term.lowercased() }!
        let lowered = Word(term: mixed.term.lowercased(), partOfSpeech: mixed.partOfSpeech,
                           hindi: "", definition: mixed.definition, example: mixed.example)
        precondition(!startupIndex.nearest(to: lowered).map(\.term).contains(mixed.term),
                     "\(lowered.term) got \(mixed.term) back as related")

        for id in ["character", "eloquence", "curiosities"] {
            let (words, index) = indexes[id]!
            let sample = words.prefix(2).map { "\($0.term) → \(index.nearest(to: $0).map(\.term).joined(separator: ", "))" }
            print("\(id): \(sample.joined(separator: " · "))")
        }
        print("\nall related-words checks passed")
    }
}
