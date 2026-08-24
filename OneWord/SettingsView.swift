//
//  SettingsView.swift
//  OneWord
//
//  Presented as a sheet from the gear button. Appearance + the dictionary. The
//  dictionary lives in the App Group, so it drives both the app and the widget.
//  Dictionaries are picked from a shelf of tappable book covers.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    @AppStorage("dictionaryID", store: AppGroup.defaults)
    private var dictionaryID = Wordbook.everydayEnglish.id
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    // Book covers on a shelf: ~2:3 portrait, laid out in flexible columns.
    private let columns = [GridItem(.adaptive(minimum: 130, maximum: 200), spacing: 20)]

    var body: some View {
        let t = Theme.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Settings").font(.title2.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Appearance")
                            .font(.headline).foregroundStyle(t.muted)
                        Picker("Appearance", selection: $appearance) {
                            ForEach(Appearance.allCases) { mode in
                                Text(mode.name).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Dictionary")
                            .font(.headline).foregroundStyle(t.muted)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                            ForEach(Wordbook.all) { book in
                                BookCover(book: book, selected: book.id == dictionaryID)
                                    .onTapGesture { select(book) }
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(t.background)
        .frame(minWidth: 520, idealWidth: 640, minHeight: 480, idealHeight: 620)
    }

    private func select(_ book: Wordbook) {
        dictionaryID = book.id
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// A rectangular book cover: gray board, a spine stripe down the left, the
/// dictionary's symbol and title. Lifts and gains a white ring when selected —
/// white, not the accent, because every cover is a dark hue.
private struct BookCover: View {
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
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
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

#Preview {
    SettingsView()
}
