# Usage — Plan

Once a week, the app files a small document of **counts** to Firestore: how many words
were read on each shelf this week, how many bookmarks exist, how often Practice, Search
and Related words were used, and which settings are on. No words, no terms, no text.
Enough to see which shelves are dead, which panes nobody opens, and whether the Hindi
line stays on. Opt-out in Settings.

> **Scope.** Grounded in the code on `feat/firebase-auth` (HEAD `8017b02`). Nothing here
> is built yet. Reads alongside [FEEDBACK_PLAN.md](FEEDBACK_PLAN.md): the wire is the same.

---

## 1. What we're reusing

| Need | Already here | File |
|---|---|---|
| Write a document to Firestore, create-only, silent retry | `publishJoinDate()` — REST `POST` with `documentId=`, 200 or 409 = done | [AuthViewModel.swift:259](../../OneWord/ViewModels/AuthViewModel.swift) |
| Firebase ID token, app-only rule | `FeedbackViewModel.send(as:)` | [FeedbackViewModel.swift](../../OneWord/ViewModels/FeedbackViewModel.swift) |
| Words read, per shelf, **with first-seen dates** | `LearnedWords.all` → `[shelf: [term: Date]]` | [LearnedWords.swift](../../OneWord/Models/LearnedWords.swift) |
| Bookmarks | `SavedWords.all.count` | [SavedWords.swift](../../OneWord/Shared/SavedWords.swift) |
| Selected dictionary | `Wordbook.selected.id` | [Wordbook.swift](../../OneWord/Models/Wordbook.swift) |
| Settings values | `showHindi`, `showExample` (App Group); `practiceEnabled`, `fluencyGoal`, doodle keys (standard) | [SettingsView.swift:20](../../OneWord/Views/SettingsView.swift) |
| Version / OS strings | `FeedbackViewModel.mailtoURL` builds them | same file |
| A Settings row with a switch and an (i) popover | `row()` + existing popover pattern | `SettingsView.swift` |

**Not added:** `FirebaseFirestore` SDK. Same reason as the other two writes.
**Not added:** an analytics SDK, event streams, session timing, or anything per-word.
Counts per week per user is the whole feature.

**Most of the report is derived, not tracked.** Words read per shelf, both lifetime and
this week, come straight from the timestamps `LearnedWords` already keeps. Bookmarks and
settings are reads. Only four things are not stored anywhere today and get a counter:
Practice reveals, Searches, Related-word taps, Launches.

---

## 2. Decisions

| Decision | Choice | Why |
|---|---|---|
| Granularity | One document per user per ISO week | "Dead shelf" is a weekly question. Daily is noise, monthly is too slow to act on. |
| Document id | `usage/{uid}_{week}` e.g. `abc123_2026-W37` | Create-only with a fixed id means the 200-or-409 retry policy from `publishJoinDate` works unchanged, and history accrues for free. No upsert, no read-before-write. |
| When it sends | On becoming active, if this week's id hasn't been marked sent | Piggybacks on the launch the user already made. No timer, no background task. |
| Counters | Reset to zero after a 200 or 409 | Each document is a clean weekly delta. A user who skips a week sends one doc covering the gap, which is fine. |
| Consent | Settings switch **Share usage counts**, default on, explained in an (i) popover and one line of copy | It is counts of your own use with your account id, sent over the same account. Default-on is defensible for that; a clear switch keeps it honest. |
| What is never sent | Terms, definitions, bookmark contents, search queries, names, email | Only integers, booleans, the shelf id, version and OS. The rule enforces field types. |
| Where it lives | `OneWord/Models/Usage.swift` (counters + snapshot, no Firebase) and `OneWord/ViewModels/UsageReporter.swift` (the POST, names FirebaseAuth) | App target only. Splitting keeps the snapshot compilable by a bare-`swiftc` gate. The widget has nothing to report. |
| Storage for counters | `UserDefaults.standard`, one integer per counter, one string for `usageSentWeek` | App-only state, same as the doodle and practice settings. |

---

## 3. The document

```
usage/{uid}_{week}
  userID        string    uid — the rule checks it
  week          string    "2026-W37" — the rule checks the id was built from it
  sentAt        timestamp client clock
  appVersion    string    "1.0 (42)"
  os            string    "Version 15.6 (Build …)"
  shelf         string    Wordbook.selected.id

  learnedTotal  map       shelf id → integer   lifetime words read, per shelf
  learnedWeek   map       shelf id → integer   words first read in the last 7 days
  bookmarks     integer
  launches      integer   this week
  practice      integer   reveals this week
  searches      integer   query went empty → non-empty, this week
  related       integer   "same vein" rows tapped, this week

  showHindi     boolean
  showExample   boolean
  practiceOn    boolean
  fluencyGoalOn boolean
  doodleIcons   boolean
```

`learnedWeek` is the shelf-health number. `learnedTotal` says how far a user got before
stopping. A shelf with lifetime reads and zero weekly reads across users is dead; a shelf
nobody ever selected is worse. Both are visible from these two maps alone.

REST envelope for reference: integers go as `{"integerValue": "3"}` (a **string**),
booleans as `{"booleanValue": true}`, maps as `{"mapValue": {"fields": {...}}}`.

---

## 4. Firestore rule (console edit, Phase 0)

```
match /usage/{id} {
  // Create-only, one per account per week, id built from the account and the week
  // so nobody can pre-fill another user's slot. Never readable from the app.
  allow create: if request.auth != null
                && request.resource.data.userID == request.auth.uid
                && request.resource.data.week is string
                && id == request.auth.uid + '_' + request.resource.data.week
                && request.resource.data.learnedWeek is map
                && request.resource.data.launches is int;
  allow read, update, delete: if false;
}
```

Addition beside `/users` and `/complaints`. Precondition, same as the Feedback audit
asked: confirm a `complaints` doc has actually landed from a build before trusting the
wire.

---

## 5. Files

| File | Status | Holds |
|---|---|---|
| `OneWord/Models/Usage.swift` | new | `enum Usage` — `Counter` cases (`launches, practice, searches, related`), `bump(_:)`, `reset()`, `weekKey(for:)`, and `snapshot() -> [String: Any]` already in REST envelope shape. Pure Foundation. |
| `OneWord/ViewModels/UsageReporter.swift` | new | `sendIfDue(as: AuthViewModel) async` — guards on the Settings switch and `usageSentWeek != weekKey`, POSTs, marks sent and resets counters on 200 or 409. ~40 lines, a copy of `publishJoinDate` with a different URL and body. |
| `OneWord/Views/RootView.swift` | edit | In the existing `.task { auth.restore() }`: `Usage.bump(.launches)` then `await reporter.sendIfDue(as: auth)`. Add `.onChange(of: scenePhase)` → active → same send. |
| `OneWord/Views/SentenceView.swift` | edit | In `advance()`, the branch that sets `revealed = true`: `Usage.bump(.practice)`. |
| `OneWord/Views/WordListView.swift` | edit | `.onChange(of: query.isEmpty) { wasEmpty, isEmpty in if wasEmpty && !isEmpty { Usage.bump(.searches) } }`. One per search session, not per keystroke. |
| `OneWord/Views/WordDetail.swift` | edit | In the related-row navigation action: `Usage.bump(.related)`. |
| `OneWord/Views/SettingsView.swift` | edit | New row **Share usage counts** in the same card as Feedback, `@AppStorage("shareUsage") = true`, (i) popover: "Once a week One Word sends how many words you read on each shelf and which panes you used, as numbers only. Never the words themselves. Tied to your account so we can tell one Mac from a thousand." |
| `tools/check_usage.sh` | new, optional | Compiles `Usage.swift` with bare `swiftc` and asserts `weekKey` for a known date and that `snapshot()` carries every key in §3. Mirror `check_learned.sh`. |
| `Docs/00_Context/PROJECT_CONTEXT.md` | edit | One bullet under current state. |

---

## 6. Phases

**Phase 0 — Console.** Add the rule. Verify a complaint has landed from this build.

**Phase 1 — Counters and snapshot.** `Usage.swift` only. Build green. Log `snapshot()`
once from a DEBUG breakpoint and eyeball the keys.

**Phase 2 — Wire the four bumps.** Four one-line edits. Build green.

**Phase 3 — Send.** `UsageReporter.swift`, the RootView hook, the Settings switch. Run,
check the Firestore console shows `usage/{uid}_{week}`. Relaunch, confirm no second
document (409 path) and counters read zero.

**Phase 4 — Gate.** `check_usage.sh` if it can compile without SwiftUI; otherwise skip
and say so in the commit.

---

## 7. Reading the data

Firestore console → `usage` → filter `week == "2026-W37"`. For more than a handful of
users, a ten-line Admin-SDK Python script that sums `learnedWeek` per shelf and counts
distinct `userID` per shelf is the whole dashboard. Add it to `tools/` the first week
the console gets tedious, not before.

---

## 8. Not doing

- Per-event streams, timestamps per action, session length, widget impressions.
- Sending when signed out. `sendIfDue` needs `auth.user` for the token, same as Feedback.
- Retrying inside a session. Failed sends try again on the next activation.
- Deleting old docs. Storage cost at this scale is nil.
