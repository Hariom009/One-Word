//
//  HistoryView.swift
//  OneWord
//
//  The History pane: any past day's word, with a date rail beside it — the day
//  set like a page number, the month grid that changes it, and the dictionary
//  History is reading in. Home is only ever today.
//
//  History's dictionary is its own. It STARTS as the app's pick and, once you
//  choose another here, stays local: Home, Search and the widget keep theirs.
//  That's why the rail opens a sheet instead of sending you to the Dictionaries
//  pane, which would change the pick for the whole app.
//

import SwiftUI

struct HistoryView: View {
    @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
    /// History's own choice. nil = still following the app's; never written back.
    @State private var localID: String?
    @State private var model = WordViewModel()
    @State private var date = Date()
    @State private var picking = false
    /// Phone only: whether the month grid is unfolded under the date.
    @State private var calendarOpen = false
    @Environment(\.colorScheme) private var scheme

    private let calendar = Calendar.current
    private var book: Wordbook { Wordbook.named(localID ?? dictionaryID) }
    /// True once History is deliberately reading somewhere else than the app is.
    private var strayed: Bool { localID != nil && localID != dictionaryID }

    /// The doodle theme's hand, for the display face. `.face()` hands back the
    /// editorial serif untouched when the handwriting switch is off.
    @Environment(\.doodle) private var doodle
    var body: some View {
        let t = Theme.of(scheme, doodle)
        Group {
            if isPhone {
                // No room for a rail beside the word on a phone: it lies flat as a
                // strip over it, and the grid unfolds under the date on demand.
                VStack(spacing: 0) {
                    strip(t)
                    WordDetail(word: model.word, shelf: book.id, embedded: true)
                }
            } else {
                HStack(alignment: .top, spacing: 0) {
                    rail(t)
                    Divider().overlay(t.hairline)
                    // The book travels with the word: reading an old Medicine day must log
                    // and draw its related words there, not in whatever Home has open.
                    // Embedded: one ground and one header across rail and word, so the glow
                    // is a single light rather than one per column.
                    WordDetail(word: model.word, shelf: book.id, embedded: true)
                }
            }
        }
        .paneBackground(t)
        .paneHeader("History") {
            // Bare arrows: nothing in this pane types, and walking day by day
            // is the whole job here. On a phone they flank the date in the strip.
            if !isPhone {
                Button { step(-1) } label: { Label("Previous Day", systemImage: "chevron.left") }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    .help("Previous day (\u{2190})")
                Button { step(1) } label: { Label("Next Day", systemImage: "chevron.right") }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .help("Next day (\u{2192})")
                    .disabled(calendar.isDateInToday(date))
            }
            WordActions(word: model.word)
        }
        .sheet(isPresented: $picking) { picker(t) }
        .onAppear { show() }
        .onChange(of: date) { show() }
        .onChange(of: book) { show() }
    }

    // MARK: - Rail

    private func rail(_ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            datePlate(t)
            rule(t)
            MonthCalendar(selection: $date) { _ in }   // the binding is the signal
            Spacer(minLength: 12)
            rule(t)
            bookRow(t)
        }
        .frame(width: 268)
    }

    private func rule(_ t: Theme) -> some View {
        Rectangle().fill(t.hairline).frame(height: 1).padding(.horizontal, 14)
    }

    /// The day you're reading, set like a page number. This used to be the window
    /// title, where it sat far from the grid that changes it.
    private func datePlate(_ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(date.formatted(.dateTime.weekday(.wide)))
                .font(.system(size: 10, weight: .bold))
                .textCase(.uppercase).tracking(1.8)
                .foregroundStyle(t.muted)
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(date.formatted(.dateTime.day()))
                    .font(doodle.face(42))
                    .tracking(doodle.tracking(42))
                    .foregroundStyle(t.ink)
                    .contentTransition(.numericText())
                Text(date.formatted(.dateTime.month(.wide).year()))
                    .font(doodle.face(15))
                    .foregroundStyle(t.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .animation(.easeOut(duration: 0.2), value: date)
    }

    /// History's dictionary, and the way to change it: a sheet, so the pick lands
    /// here and nowhere else.
    private func bookRow(_ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { picking = true } label: {
                HStack(spacing: 10) {
                    BookChip(book: book)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Reading from")
                            .font(.system(size: 9, weight: .bold))
                            .textCase(.uppercase).tracking(1.4)
                            .foregroundStyle(t.muted)
                        Text(book.shortName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(t.muted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Choose the dictionary History reads \u{2014} the rest of the app keeps its own")

            // Say it out loud when the two disagree, so a stray pick here is never
            // mistaken for the app having switched.
            if strayed {
                strayNote(t)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 11)
            }
        }
        .animation(.easeOut(duration: 0.18), value: strayed)
    }

    private func strayNote(_ t: Theme) -> some View {
        HStack(spacing: 6) {
            Text("History only")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(t.muted)
            Spacer(minLength: 0)
            Button("Match app") { localID = nil }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(t.ink)
        }
    }

    // MARK: - Phone strip

    /// The rail laid flat, as a calendar page: the day set in the middle with
    /// yesterday and tomorrow on either side, the month grid unfolding under it on
    /// a tap, and the book as a small pill beneath. A pick folds the grid back, so
    /// the word is never more than one tap away.
    private func strip(_ t: Theme) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                pager(-1, "chevron.left", "Previous day", t)
                Spacer(minLength: 0)
                Button {
                    withAnimation(.easeOut(duration: 0.22)) { calendarOpen.toggle() }
                } label: {
                    VStack(spacing: 3) {
                        Text(date.formatted(.dateTime.weekday(.wide)))
                            .font(.system(size: 10, weight: .bold))
                            .textCase(.uppercase).tracking(1.8)
                            .foregroundStyle(t.muted)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(dayTitle)
                                .font(doodle.face(22))
                                .tracking(doodle.tracking(22))
                                .foregroundStyle(t.ink)
                                .lineLimit(1)
                                .contentTransition(.numericText())
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(t.muted)
                                .rotationEffect(.degrees(calendarOpen ? 180 : 0))
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pick a day")
                .accessibilityValue(date.formatted(date: .long, time: .omitted))
                .accessibilityHint(calendarOpen ? "Hides the calendar" : "Shows the calendar")
                Spacer(minLength: 0)
                pager(1, "chevron.right", "Next day", t)
                    .disabled(calendar.isDateInToday(date))
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .animation(.easeOut(duration: 0.2), value: date)

            if calendarOpen {
                MonthCalendar(selection: $date) { _ in
                    withAnimation(.easeOut(duration: 0.22)) { calendarOpen = false }
                }
                .transition(.opacity)
            }

            // The book, and a way back when History has strayed from the app's pick.
            HStack(spacing: 10) {
                Button { picking = true } label: {
                    HStack(spacing: 6) {
                        BookChip(book: book, height: 18)
                        Text(book.shortName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(t.muted)
                    }
                    .padding(.leading, 6)
                    .padding(.trailing, 10)
                    .padding(.vertical, 5)
                    .background(t.ink.opacity(0.06), in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reading from \(book.shortName)")
                .accessibilityHint("Chooses the dictionary History reads")

                if strayed {
                    Button("Match app") { localID = nil }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(t.muted)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 14)
            .animation(.easeOut(duration: 0.18), value: strayed)

            Rectangle().fill(t.hairline).frame(height: 1)
        }
    }

    /// "October 3", with the year only once it isn't this one.
    private var dayTitle: String {
        calendar.isDate(date, equalTo: .now, toGranularity: .year)
            ? date.formatted(.dateTime.month(.wide).day())
            : date.formatted(.dateTime.month(.wide).day().year())
    }

    /// One day either way. A bare chevron on a thumb-sized target, no tile: the
    /// strip is a page, and these are its corners.
    private func pager(_ days: Int, _ symbol: String, _ label: String, _ t: Theme) -> some View {
        Button { step(days) } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(t.ink)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Picker sheet

    private func picker(_ t: Theme) -> some View {
        let selection = Binding(get: { book.id }, set: { localID = $0 })
        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Read History In")
                        .font(doodle.face(19))
                        .foregroundStyle(t.ink)
                    Text("Stays in History \u{2014} Home and the widget keep \(Wordbook.named(dictionaryID).shortName). Search spans every dictionary.")
                        .font(.system(size: 11))
                        .foregroundStyle(t.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button("Done") { picking = false }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            Rectangle().fill(t.hairline).frame(height: 1)
            // No dismiss on pick: the sheet stays up so the book's turn plays out, same as
            // the Dictionaries pane. Done (or Esc) closes it.
            DictionaryShelf(selection: selection, padding: 20)
        }
        // A phone's sheet sizes itself; the Mac's needs telling.
        .frame(width: isPhone ? nil : 560, height: isPhone ? nil : 520)
        .background(t.background)
    }

    // MARK: - Date

    private func step(_ days: Int) {
        guard let next = calendar.date(byAdding: .day, value: days, to: date),
              calendar.startOfDay(for: next) <= calendar.startOfDay(for: .now) else { return }
        date = next
    }

    private func show() { model.show(book, on: date) }
}

#Preview {
    NavigationStack { HistoryView() }
        .environment(RelatedWordsStore())
        .environment(PremiumViewModel())
}
