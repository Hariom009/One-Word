//
//  DictionaryPicker.swift
//  OneWord
//
//  The shelf of dictionary covers. `DictionaryShelf` is the shelf itself over
//  ANY selection; `DictionaryPicker` is the Dictionaries pane, which binds it to
//  the app-wide pick. History binds the same shelf to a choice of its own.
//

import SwiftUI
import WidgetKit

/// The covers, in a grid, over whatever `selection` you hand it. Nothing here
/// touches App Group storage — the owner decides how far the pick reaches.
struct DictionaryShelf: View {
    @Binding var selection: String
    /// Narrower covers for the History sheet; the pane keeps the roomy default.
    var minimum: CGFloat = 130
    var padding: CGFloat = 24
    var onPick: (Wordbook) -> Void = { _ in }

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.of(scheme)
        // Book covers on a shelf: ~2:3 portrait, laid out in flexible columns.
        let columns = [GridItem(.adaptive(minimum: minimum, maximum: minimum * 1.54), spacing: 20)]
        return ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                ForEach(Wordbook.all) { book in
                    BookCover(book: book, selected: book.id == selection)
                        .onTapGesture {
                            selection = book.id
                            onPick(book)
                        }
                }
            }
            .padding(padding)
        }
        .background(t.background)
    }
}

/// The Dictionaries pane: the shelf, bound to the app-wide pick. `onPick` lets
/// the shell move on once you've chosen (the sidebar sends you back to Home).
struct DictionaryPicker: View {
    var onPick: () -> Void = {}

    @AppStorage("dictionaryID", store: AppGroup.defaults)
    private var dictionaryID = Wordbook.everydayEnglish.id

    var body: some View {
        DictionaryShelf(selection: $dictionaryID) { _ in
            WidgetCenter.shared.reloadAllTimelines()
            onPick()   // picking one is the only reason you're on this pane
        }
        .navigationTitle("Dictionaries")
    }
}

/// A rectangular book cover: gray board, a spine stripe down the left, the
/// dictionary's symbol and title. Lifts and gains a white ring when selected —
/// white, not the accent, because every cover is a dark hue.
struct BookCover: View {
    let book: Wordbook
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: book.symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
            Spacer(minLength: 0)
            Text(book.name)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
        .background(book.coverColor, in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            // Spine
            Rectangle().fill(.black.opacity(0.22)).frame(width: 9)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(selected ? Color.white : .clear, lineWidth: 3)
        )
        .overlay(alignment: .topTrailing) {
            if selected {
                // plated: every cover is a dark hue, in both themes — without the
                // chip the drawing's black tick would sit inside its green ring
                // against near-black and read as an empty ring.
                GlyphIcon(.selected, size: 20, plated: true)
                    .foregroundStyle(.black, .white)
                    .padding(8)
            }
        }
        .shadow(color: .black.opacity(selected ? 0.28 : 0.15),
                radius: selected ? 10 : 5, x: 0, y: selected ? 5 : 3)
        .scaleEffect(selected ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel(book.name)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
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
