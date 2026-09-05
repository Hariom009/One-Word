//
//  SentencesCheck.swift — standalone self-check for the practice corpus.
//  Not a target member; compiles the real source. Run: tools/check_sentences.sh
//
//  precondition, not assert — check_sentences.sh compiles with -O, which strips
//  assert() outright (the same trap WordProviderCheck.swift documents).
//

import Foundation

let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().appendingPathComponent("OneWord/Models")
let corpus = Sentences.decode(try! Data(contentsOf: dir.appendingPathComponent("sentences.json")))

@main
enum Check {
    static func main() {
        // 1. Non-empty, and every pair carries both halves. A blank side renders
        //    as an empty reel or an empty reveal, with nothing to explain it.
        precondition(!corpus.isEmpty, "sentences.json is empty")
        for s in corpus {
            precondition(!s.en.trimmingCharacters(in: .whitespaces).isEmpty, "blank en beside \(s.de)")
            precondition(!s.de.trimmingCharacters(in: .whitespaces).isEmpty, "blank de for \(s.en)")
        }

        // 2. English is the id, and a duplicate reads on screen as a stuck reel.
        let unique = Set(corpus.map(\.en))
        precondition(unique.count == corpus.count,
                     "\(corpus.count - unique.count) duplicate English sentences")

        // 3. An untranslated row that slipped through the corpus build.
        for s in corpus { precondition(s.en != s.de, "untranslated: \(s.en)") }

        // 4. The finding this check exists for. random(excluding:) must never
        //    return what it was told to skip...
        for s in corpus {
            for _ in 0..<100 {
                precondition(Sentences.random(excluding: s, in: corpus) != s,
                             "reel repeated \(s.en)")
            }
        }
        // ...and must TERMINATE on a one-entry corpus, where "not the same" is
        // impossible. Reject-and-retry hangs here; index arithmetic returns.
        precondition(Sentences.random(excluding: corpus[0], in: [corpus[0]]) == corpus[0],
                     "single-entry corpus must return its only entry, not loop")

        // 5. The skip must not bias the draw. Excluding one entry should hit the
        //    other n-1 evenly — an off-by-one in the index shift shows up as one
        //    entry never drawn, or one drawn twice as often. Bounds are DERIVED
        //    from the corpus size: hardcoding them for 20 entries is exactly how
        //    this check broke when the corpus grew to 313.
        let expected = 200
        let others = corpus.count - 1
        var hits = [String: Int]()
        for _ in 0..<(expected * others) {
            hits[Sentences.random(excluding: corpus[0], in: corpus).en, default: 0] += 1
        }
        let (lo, hi) = (hits.values.min() ?? 0, hits.values.max() ?? 0)
        // -O strips precondition messages, so print the numbers before asserting them.
        print("draw over \(others) entries: min \(lo), max \(hi), expected ~\(expected)")
        precondition(hits.count == others,
                     "skip biased the draw: \(hits.count) distinct, expected \(others)")
        precondition(Double(lo) > Double(expected) * 0.6 && Double(hi) < Double(expected) * 1.4,
                     "uneven draw: \(lo)-\(hi), expected ~\(expected)")

        print("\(corpus.count) sentences \u{00B7} all checks passed")
    }
}
