//
//  DictionaryPicker.swift
//  OneWord
//
//  The bookshelf. `DictionaryShelf` is the shelf itself over ANY selection;
//  `DictionaryPicker` is the Dictionaries pane, which binds it to the app-wide
//  pick. History binds the same shelf to a choice of its own.
//

import SwiftUI
import AppKit
import WidgetKit

/// The shelf's flip: a half-second book pull, one beat like the swap itself.
/// Loaded once, same shape as SentenceView's shuffle.
@MainActor private let flipSound = Bundle.main
    .url(forResource: "book_pull", withExtension: "mp3")
    .flatMap { NSSound(contentsOf: $0, byReference: true) }

/// One plank: the chosen book stands face-out and large on the left, the rest stand
/// spine-out beside it in catalogue order. Tapping a spine pulls that book off the
/// shelf — it turns to face you as it grows into the front — while the one it
/// replaces turns back to its spine and slides home into its gap. Nothing here
/// touches App Group storage — the owner decides how far the pick reaches.
/// Bookmarks has its own pane, so it isn't on the shelf.
struct DictionaryShelf: View {
    @Binding var selection: String
    var padding: CGFloat = 28
    var onPick: (Wordbook) -> Void = { _ in }

    @Environment(\.colorScheme) private var scheme
    /// For Midnight's palette behind the shelf.
    @Environment(\.doodle) private var doodle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The book standing face-out. Its own state rather than `selection`, so the turn
    /// animates wherever the owner stores the pick.
    @State private var front: String
    /// True while a swap is in flight. Taps in that window are dropped, so a burst
    /// of clicks gives one clean swap at a time, not the sound restarting under each.
    @State private var swapping = false

    private static let books = Wordbook.all.filter { $0.id != Wordbook.saved.id }
    // ponytail: 0.69 is the widest cover art (570×827); the narrower ones fit by height.
    static let coverAspect: CGFloat = 0.69
    /// How far down its art a cover's board reaches; below it only the ribbon hangs.
    // ponytail: measured off the eight `Dictionary_of_*` covers (0.936–0.939). Every cover must be
    // cut out tight to the book: a transparent margin draws it short of its spine, so it pops mid-turn.
    static let boardFoot: CGFloat = 0.936
    /// A spine's width as a share of its book's height — dictionaries are thick books.
    static let thickness: CGFloat = 0.17
    /// How large the spines stand beside the face-out book, when the width allows.
    private static let spineScale: CGFloat = 0.85
    private static let spineGap: CGFloat = 2

    init(selection: Binding<String>, padding: CGFloat = 28, onPick: @escaping (Wordbook) -> Void = { _ in }) {
        _selection = selection
        self.padding = padding
        self.onPick = onPick
        let id = selection.wrappedValue
        _front = State(initialValue: Self.books.contains { $0.id == id } ? id : Self.books[0].id)
    }

    /// The board every book stands on: the palette's surface under a lit top edge,
    /// shadowed like the covers, so it reads on paper, night and Midnight's navy alike.
    private func plank(_ t: Theme) -> some View {
        t.surface
            .overlay(alignment: .top) { t.hairline.frame(height: 1) }
            .frame(height: 10)
            .clipShape(RoundedRectangle(cornerRadius: t.radius(2)))
            .shadow(color: .black.opacity(0.18), radius: 6, y: 4)
    }

    /// Where each book stands: the front one at the left edge, the spines packed left
    /// to right from `start` in catalogue order, each as thick as it is tall.
    private func positions(from start: CGFloat, spine: CGFloat) -> [String: CGFloat] {
        var xs: [String: CGFloat] = [front: 0]
        var x = start
        for book in Self.books where book.id != front {
            xs[book.id] = x
            x += spine * book.height + Self.spineGap
        }
        return xs
    }

    var body: some View {
        let t = Theme.of(scheme, doodle)
        return GeometryReader { g in
            let w: CGFloat = max(0, g.size.width - padding * 2)
            let h: CGFloat = max(0, g.size.height - padding * 2)
            // The cover art's height at full size: a third of the width, or what the
            // height leaves above the ribbon and caption (art + 26 in all).
            let art: CGFloat = max(1, min(w * 0.33 / Self.coverAspect, h - 26))
            let floor: CGFloat = max(0, (h - art - 26) / 2) + art * Self.boardFoot
            // Air between the face-out book and the first spine: a tenth of the art, so it keeps
            // its proportion from the History sheet to a full-screen window.
            let shelfStart: CGFloat = art * (Self.coverAspect + 0.1)
            // Shrink the spines if all of them wouldn't fit beside the front book.
            let room: CGFloat = w - shelfStart - Self.spineGap * CGFloat(Self.books.count)
            let tall: CGFloat = art * Self.thickness * Self.books.map(\.height).reduce(0, +)
            let k: CGFloat = max(0, min(Self.spineScale, room / tall))
            let xs = positions(from: shelfStart, spine: art * Self.thickness * k)

            ZStack(alignment: .topLeading) {
                plank(t).offset(y: floor)

                ForEach(Self.books) { book in
                    let isFront = book.id == front
                    let scale = (isFront ? 1 : k) * book.height
                    ShelfBook(book: book, art: art, turn: isFront ? 1 : 0)
                        // Gestures before the transforms, so the tap target moves and scales with the book.
                        .contentShape(Rectangle())
                        .onTapGesture { pick(book) }
                        .allowsHitTesting(!isFront)
                        .accessibilityElement()
                        .accessibilityLabel(book.name)
                        .accessibilityAddTraits(isFront ? .isSelected : .isButton)
                        .accessibilityAction { pick(book) }
                        // Transforms, not layout: the flight never reflows the shelf. The board stands on the plank.
                        .scaleEffect(scale, anchor: .topLeading)
                        .offset(x: xs[book.id] ?? 0, y: floor - art * Self.boardFoot * scale)
                        // The book coming to the front flies over the spines it crosses.
                        .zIndex(isFront ? 1 : 0)
                }

                HStack(spacing: 6) {
                    Text("\(Wordbook.named(front).entryCount, format: .number) entries")
                        .foregroundStyle(t.ink)
                    Text("\u{00B7} Selected for word of the day")
                        .foregroundStyle(t.muted)
                }
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                // Clear of the front book's ribbon, which hangs 6.4% of its art past the plank.
                .offset(y: floor + art * (1 - Self.boardFoot) + 10)
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .padding(padding)
        }
        .paneBackground(t)
        // Warm every book's decode off the main thread, so the first swap to a book
        // doesn't stall the flight on a multi-MB JSON parse for its entry count.
        .task {
            let ids = Self.books.map(\.id)
            await Task.detached(priority: .utility) {
                for id in ids { _ = WordProvider(resource: id) }
            }.value
        }
    }

    /// Pull the tapped book off the shelf and tell the owner. You stay on the
    /// shelf — picking is the whole job, there's nowhere to go next.
    private func pick(_ book: Wordbook) {
        guard !swapping, book.id != front else { return }
        selection = book.id
        onPick(book)
        guard !reduceMotion else { front = book.id; return }
        swapping = true
        flipSound?.currentTime = 0
        flipSound?.play()
        withAnimation(.smooth(duration: 0.6)) {
            front = book.id
        } completion: {
            swapping = false
        }
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
        .paneHeader("Dictionaries")
    }
}

/// One book, turning between spine-out (`turn` 0) and face-out (1): the reference
/// bookshelf's CSS rotateY, drawn flat. Each face is laid out once at full size and
/// only squeezed and shaded as it turns, so nothing re-lays-out mid-flight.
private struct ShelfBook: View, Animatable {
    let book: Wordbook
    /// The cover art's height at full size; the shelf scales the whole book from there.
    let art: CGFloat
    var turn: CGFloat

    var animatableData: CGFloat {
        get { turn }
        set { turn = newValue }
    }

    var body: some View {
        let a = turn * .pi / 2
        let spine = art * DictionaryShelf.thickness
        let cover = art * DictionaryShelf.coverAspect
        ZStack(alignment: .topLeading) {
            BookSpine(book: book, width: spine, height: art * DictionaryShelf.boardFoot)
                .brightness(-0.3 * sin(a))
                .scaleEffect(x: cos(a), y: 1, anchor: .leading)
            // The cover hinges out from the spine's edge as the spine turns away.
            Image(book.image)
                .resizable()
                .scaledToFit()
                .frame(width: cover, height: art, alignment: .leading)
                .brightness(-0.3 * cos(a))
                .scaleEffect(x: sin(a), y: 1, anchor: .leading)
                .offset(x: spine * cos(a))
        }
        .frame(width: spine * cos(a) + cover * sin(a), height: art, alignment: .topLeading)
        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
        // Lifted off the plank mid-turn, set down again as it lands.
        .offset(y: -art * 0.06 * sin(.pi * turn))
    }
}

/// A book's spine, drawn: the cover's cloth rounded by light across its width, gilt
/// bands at head and foot, and the short title running down it the way English
/// spines read.
private struct BookSpine: View {
    let book: Wordbook
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        // Lettered like the art prints its titles: ink on pale linen, cream on the rest.
        let ink = book.isLight ? Color(hex: 0x2A2825) : Color(hex: 0xF1E6D2)
        let bands = VStack(spacing: height * 0.008) {
            ink.frame(height: max(1, height * 0.004))
            ink.frame(height: max(1, height * 0.004))
        }
        .opacity(0.55)
        return book.coverColor
            .overlay {
                LinearGradient(stops: [
                    .init(color: .black.opacity(0.3), location: 0),
                    .init(color: .white.opacity(0.12), location: 0.3),
                    .init(color: .clear, location: 0.65),
                    .init(color: .black.opacity(0.35), location: 1),
                ], startPoint: .leading, endPoint: .trailing)
            }
            .overlay(alignment: .top) { bands.padding(.top, height * 0.07) }
            .overlay(alignment: .bottom) { bands.padding(.bottom, height * 0.07) }
            .overlay {
                Text(book.shortName)
                    .font(.serif(width * 0.4, .medium))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: height * 0.66)
                    .rotationEffect(.degrees(90))
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: width * 0.1))
    }
}

/// A cover shrunk to a chip: the same cloth and symbol as the shelf, small enough
/// to sit in a row that names the book beside it.
struct BookChip: View {
    let book: Wordbook
    var height: CGFloat = 32

    var body: some View {
        Image(systemName: book.symbol)
            .font(.system(size: height * 0.38, weight: .semibold))
            .foregroundStyle(book.isLight ? Color.black : .white)
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
