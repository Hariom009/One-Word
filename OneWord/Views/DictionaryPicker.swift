//
//  DictionaryPicker.swift
//  OneWord
//
//  The shelf of painted dictionary covers. `DictionaryShelf` is the shelf itself over
//  ANY selection; `DictionaryPicker` is the Dictionaries pane, which binds it to
//  the app-wide pick. History binds the same shelf to a choice of its own.
//

import SwiftUI
import AppKit
import WidgetKit

/// The shelf's flip: the practice roll's shuffle clip, cut at a second — a swap
/// is a one-beat interaction, not a roll. Loaded once, same shape as SentenceView.
@MainActor private let flipSound = Bundle.main
    .url(forResource: "practice_sentence_shuffle", withExtension: "wav")
    .flatMap { NSSound(contentsOf: $0, byReference: true) }
private let flipSoundDuration = 1.0

/// The shelf: the chosen book stands large on the left, the rest sit small in
/// a grid beside it. Tapping a small book swaps it into the big slot (and picks
/// it). Nothing here touches App Group storage — the owner decides how far the
/// pick reaches. Bookmarks has its own pane, so it isn't on the shelf.
struct DictionaryShelf: View {
    @Binding var selection: String
    var padding: CGFloat = 28
    var onPick: (Wordbook) -> Void = { _ in }

    @Environment(\.colorScheme) private var scheme
    @Namespace private var shelf
    /// Shelf order; `order[0]` is the book standing large. Starts with the
    /// selection in front, then the rest in catalogue order.
    @State private var order: [Wordbook]
    /// Pending cut of the flip sound; a fresh pick cancels it so the new flip
    /// gets its full second rather than the tail of the last one's.
    @State private var flipCut: Task<Void, Never>?

    init(selection: Binding<String>, padding: CGFloat = 28, onPick: @escaping (Wordbook) -> Void = { _ in }) {
        _selection = selection
        self.padding = padding
        self.onPick = onPick
        let books = Wordbook.all.filter { $0.id != Wordbook.saved.id }
        let front = books.filter { $0.id == selection.wrappedValue }
        _order = State(initialValue: front + books.filter { $0.id != selection.wrappedValue })
    }

    var body: some View {
        let t = Theme.of(scheme)
        return GeometryReader { g in
            ScrollView {
                HStack(alignment: .top, spacing: padding) {
                    VStack(spacing: 10) {
                        BookCover(book: order[0], large: true)
                            .matchedGeometryEffect(id: order[0].id, in: shelf)
                        HStack(spacing: 6) {
                            Text("\(order[0].entryCount, format: .number) entries")
                                .foregroundStyle(t.ink)
                            Text("\u{00B7} Selected for word of the day")
                                .foregroundStyle(t.muted)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    }
                    .frame(width: g.size.width * 0.4)

                    // Three across, like the mockup, whatever the window width.
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3),
                              alignment: .leading, spacing: 24) {
                        ForEach(order.dropFirst()) { book in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DICTIONARY OF")
                                    .font(.system(size: 11, weight: .medium))
                                    .tracking(1.6)
                                    .foregroundStyle(t.muted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                BookCover(book: book)
                                    .matchedGeometryEffect(id: book.id, in: shelf)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { pick(book) }
                            .accessibilityElement()
                            .accessibilityLabel(book.name)
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                }
                .padding(padding)
            }
        }
        .background(t.background)
    }

    /// Swap the tapped book with the one in front and tell the owner. You stay
    /// on the shelf — picking is the whole job, there's nowhere to go next.
    private func pick(_ book: Wordbook) {
        guard let i = order.firstIndex(of: book) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { order.swapAt(0, i) }
        flipCut?.cancel()
        flipSound?.currentTime = 0
        flipSound?.play()
        flipCut = Task {
            guard (try? await Task.sleep(for: .seconds(flipSoundDuration))) != nil else { return }
            flipSound?.stop()
        }
        selection = book.id
        onPick(book)
    }
}

/// The Dictionaries pane: the shelf, bound to the app-wide pick.
struct DictionaryPicker: View {
    @AppStorage("dictionaryID", store: AppGroup.defaults)
    private var dictionaryID = Wordbook.everydayEnglish.id

    var body: some View {
        DictionaryShelf(selection: $dictionaryID) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
        .navigationTitle("Dictionaries")
    }
}

/// A painted book cover with the title lettered on its front board. Large
/// covers carry "DICTIONARY OF" over the name; small ones just the name (the
/// shelf captions them). Type is sized off the cover's width so it fits either.
struct BookCover: View {
    let book: Wordbook
    var large = false

    /// Cream lettering, like foil on the board.
    private let foil = Color(hex: 0xF4E3B8)

    var body: some View {
        Image(book.image)
            .resizable()
            .scaledToFit()
            .overlay {
                GeometryReader { g in
                    let w = g.size.width
                    VStack(spacing: w * 0.02) {
                        if large {
                            Text("DICTIONARY OF")
                                .font(.serif(w * 0.038))
                                .tracking(w * 0.012)
                                .foregroundStyle(foil.opacity(0.85))
                        }
                        Text(book.shortName)
                            .font(.serif(w * (large ? 0.07 : 0.062), large ? .medium : .regular))
                            .foregroundStyle(foil)
                            // The big board fits any name on one line; the small ones may wrap.
                            .lineLimit(large ? 1 : 2)
                    }
                    .textCase(large ? nil : .uppercase)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    // ponytail: the board sits at x 22–92% / y 12–98% of the art; foot of the board, centred on it.
                    .frame(width: w * 0.6)
                    .position(x: w * 0.575, y: g.size.height * 0.82)
                }
            }
            .shadow(color: .black.opacity(0.18), radius: large ? 14 : 6, y: large ? 8 : 3)
    }

}

/// A cover shrunk to a chip: the same hue, spine and symbol as the shelf, small
/// enough to sit in a row that names the book beside it.
struct BookChip: View {
    let book: Wordbook
    var height: CGFloat = 32

    var body: some View {
        Image(systemName: book.symbol)
            .font(.system(size: height * 0.38, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: height * 0.8, height: height)
            .background(book.coverColor)
            .overlay(alignment: .leading) {
                Rectangle().fill(.black.opacity(0.22)).frame(width: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    DictionaryPicker()
}
