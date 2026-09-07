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
    @Environment(\.colorScheme) private var scheme

    private let calendar = Calendar.current
    private var book: Wordbook { Wordbook.named(localID ?? dictionaryID) }
    /// True once History is deliberately reading somewhere else than the app is.
    private var strayed: Bool { localID != nil && localID != dictionaryID }

    /// The doodle theme's hand, for the display face. `.face()` hands back the
    /// editorial serif untouched when the handwriting switch is off.
    @Environment(\.doodle) private var doodle
    var body: some View {
        let t = Theme.of(scheme)
        HStack(alignment: .top, spacing: 0) {
            rail(t)
            Divider().overlay(t.hairline)
            // The book travels with the word: reading an old Medicine day must log
            // and draw its related words there, not in whatever Home has open.
            WordDetail(word: model.word, shelf: book.id)
        }
        .background(t.background)
        .navigationTitle("History")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                // Bare arrows: nothing in this pane types, and walking day by day
                // is the whole job here.
                Button { step(-1) } label: { Label("Previous Day", systemImage: "chevron.left") }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    .help("Previous day (\u{2190})")
                Button { step(1) } label: { Label("Next Day", systemImage: "chevron.right") }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .help("Next day (\u{2192})")
                    .disabled(calendar.isDateInToday(date))
            }
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
                .padding(.horizontal, 14)
                .padding(.bottom, 11)
            }
        }
        .animation(.easeOut(duration: 0.18), value: strayed)
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
            DictionaryShelf(selection: selection, padding: 20) { _ in picking = false }
        }
        .frame(width: 560, height: 520)
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
}
