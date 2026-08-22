//
//  WordProviderCheck.swift — standalone self-check for the day→word mapping.
//  Not a target member; compiles the real source. Run: tools/check_words.sh
//

import Foundation

let books = ["words", "emotions", "medical", "philosophy", "character", "eloquence", "curiosities", "startup"]
let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().appendingPathComponent("OneWord/Shared")
let cal = Calendar(identifier: .gregorian)
let today = Date()

func load(_ id: String) -> WordProvider {
    let data = try! Data(contentsOf: dir.appendingPathComponent("\(id).json"))
    let words = try! JSONDecoder().decode([Word].self, from: data)
    return WordProvider(words: words, seed: WordProvider.seed(for: id), calendar: cal)
}

/// File positions the given dictionary serves over `days` consecutive days.
func run(_ p: WordProvider, days: Int) -> [Int] {
    (0..<days).map { d in
        p.allWords.firstIndex(of: p.word(for: cal.date(byAdding: .day, value: d, to: today)!))!
    }
}

@main
enum Check {
    static func main() {
        let providers = books.map { ($0, load($0)) }

        // 1. A dictionary never repeats a word until it has shown all of them.
        for (id, p) in providers {
            let n = p.allWords.count
            let cycle = Set((0..<n).map { p.word(for: today, offset: $0).term })
            assert(cycle.count == n, "\(id): cycle covers \(cycle.count)/\(n), not the whole book")
        }

        // 2. The reported bug: every 20-word book opened on the same file index,
        //    because the index was days % count with no per-dictionary seed.
        let sameSize = Dictionary(grouping: providers, by: { $0.1.allWords.count })
        for (n, group) in sameSize where group.count > 1 {
            let orders = group.map { run($0.1, days: n) }
            assert(Set(orders).count == group.count,
                   "\(group.map(\.0)) share a reading order at n=\(n)")
        }

        // 3. Consecutive days don't walk the file top-to-bottom.
        for (id, p) in providers where p.allWords.count > 6 {
            let r = run(p, days: 6)
            assert(!zip(r, r.dropFirst()).allSatisfy { $1 == $0 + 1 }, "\(id): still sequential \(r)")
        }

        // 4. Same day + same seed = same word, always — the app and the widget
        //    build separate providers and must never disagree.
        for (id, p) in providers {
            assert(load(id).word(for: today).term == p.word(for: today).term, "\(id): not deterministic")
        }

        for (id, p) in providers {
            let terms = (0..<3).map { p.word(for: cal.date(byAdding: .day, value: $0, to: today)!).term }
            print("\(id.padding(toLength: 12, withPad: " ", startingAt: 0)) n=\(p.allWords.count)"
                  + "\tpositions \(run(p, days: 5))\t\(terms.joined(separator: ", "))")
        }
        print("\nall checks passed")
    }
}
