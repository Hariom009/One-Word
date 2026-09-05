//
//  ProfileView.swift
//  OneWord
//
//  One number: how many words you've chosen to keep, and the way in to the
//  Learned log — which lives here rather than in the sidebar.
//
//  Dumb view: the count lives in ProfileViewModel.
//

import SwiftUI
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct ProfileView: View {
    @Environment(\.colorScheme) private var scheme

    @State private var model = ProfileViewModel()

    var body: some View {
        let t = Theme.of(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(model.bookmarks)")
                    .font(.serif(64))
                    .foregroundStyle(t.ink)
                    .contentTransition(.numericText())
                Text(model.bookmarks == 1 ? "bookmark" : "bookmarks")
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase).tracking(2)
                    .foregroundStyle(t.muted)
            }
            .accessibilityElement(children: .combine)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)

            NavigationLink {
                LearnedListView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal")
                    Text("Learned")
                        .font(.system(size: 13))
                    Spacer(minLength: 6)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(t.muted)
                }
                .foregroundStyle(t.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(t.surface, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
        }
        .background(t.background)
        .navigationTitle("Profile")
        .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
            model.refresh()
        }
        .task {
            model.refresh()
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
