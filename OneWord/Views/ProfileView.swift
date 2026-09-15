//
//  ProfileView.swift
//  OneWord
//
//  Who you are: your face and name, what you've collected, and the details behind
//  the account. The ways in to the Learned log and to Settings live here too
//  (rather than in the sidebar), and so does signing out.
//
//  Only ever reached signed in — RootView gates the whole shell behind SignInView —
//  so there is no signed-out branch here. Signing out drops you back to the door.
//
//  Editing is in place rather than in a sheet: one pane, one Edit button, and the
//  header shows the draft as you type. Drafts only land on Save, so Cancel really
//  cancels and the sidebar chip doesn't flicker through every keystroke.
//
//  Dumb view: the counts live in ProfileViewModel, the session in AuthViewModel,
//  and the three editable fields in UserDefaults (see Profile.swift).
//

import SwiftUI
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct ProfileView: View {
    /// So the bookmark count can send you to the Bookmarks pane rather than
    /// pushing a second copy of the same list on top of Profile.
    @Binding var pane: Pane
    @Environment(\.colorScheme) private var scheme

    @State private var model = ProfileViewModel()
    // Owned by the app so the sidebar chip shows the same user. RootView restores it.
    @Environment(AuthViewModel.self) private var auth

    // Yours to set. Google owns the email and the join date; these three are ours.
    @AppStorage("profileName") private var name = ""
    @AppStorage("profileGender") private var gender = Gender.unspecified.rawValue
    @AppStorage("profileAvatar") private var avatar = Avatar.account.rawValue
    /// Set in Settings. Off, the raw count above is the whole story.
    @AppStorage("fluencyGoal") private var fluencyGoal = false

    @State private var editing = false
    @State private var draftName = ""
    @State private var draftGender = Gender.unspecified.rawValue
    @State private var draftAvatar = Avatar.account.rawValue

    /// What to call you: your own name if you set one, else the one Google gave.
    private var shownName: String {
        name.isEmpty ? (auth.displayName ?? "Signed in") : name
    }

    /// The face on show — the draft while editing, so picking a tile changes the
    /// big avatar under your cursor immediately.
    private var shownAvatar: Avatar {
        Avatar(stored: editing ? draftAvatar : avatar)
    }

    /// The doodle theme's hand, for the display face. `.face()` hands back the
    /// editorial serif untouched when the handwriting switch is off.
    @Environment(\.doodle) private var doodle
    var body: some View {
        let t = Theme.of(scheme, doodle)
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header(t)
                if editing { picture(t) }
                stats(t)
                if fluencyGoal { goal(t) }
                details(t)
                rows(t)
                footer(t)
            }
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .paneBackground(t)
        .paneHeader("Profile")
        .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
            model.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: LearnedWords.didChange)) { _ in
            model.refresh()
        }
        .task { model.refresh() }
    }

    // MARK: - Header

    /// Face, name, email, and the one button that puts the pane into edit mode.
    private func header(_ t: Theme) -> some View {
        HStack(alignment: .center, spacing: 18) {
            AvatarFace(avatar: shownAvatar, url: auth.photoURL, size: 76, muted: t.muted)
                .overlay(Circle().strokeBorder(t.hairline))

            VStack(alignment: .leading, spacing: 5) {
                if editing {
                    // The headword face, in a field — the name stays the biggest
                    // thing on the pane whether you're reading it or typing it.
                    TextField("Your name", text: $draftName)
                        .textFieldStyle(.plain)
                        .font(doodle.face(28))
                        .foregroundStyle(t.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(t.surface, in: RoundedRectangle(cornerRadius: t.radius(8)))
                        .overlay(RoundedRectangle(cornerRadius: t.radius(8)).strokeBorder(t.hairline))
                        .onSubmit(save)
                } else {
                    Text(shownName)
                        .font(doodle.face(28))
                        .tracking(doodle.tracking(28))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                }
                if let email = auth.email {
                    Text(email)
                        .font(.system(size: 12))
                        .foregroundStyle(t.muted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)
            editControls(t)
        }
    }

    @ViewBuilder private func editControls(_ t: Theme) -> some View {
        if editing {
            HStack(spacing: 6) {
                capsuleButton("Cancel", t, filled: false) { editing = false }
                capsuleButton("Save", t, filled: true, action: save)
            }
        } else {
            capsuleButton("Edit", t, filled: false) {
                // Prefill with what's on screen, so editing starts from your name
                // rather than from an empty box.
                draftName = shownName
                draftGender = gender
                draftAvatar = shownAvatar.rawValue
                editing = true
            }
        }
    }

    private func save() {
        // Blank means "go back to following the Google account", not a blank name.
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        name = trimmed == (auth.displayName ?? "") ? "" : trimmed
        gender = draftGender
        avatar = draftAvatar
        editing = false
    }

    private func capsuleButton(_ title: String, _ t: Theme,
                               filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase).tracking(1.5)
                .foregroundStyle(filled ? t.background : t.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(filled ? t.ink : t.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(filled ? .clear : t.hairline))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats

    private func stats(_ t: Theme) -> some View {
        HStack(alignment: .top, spacing: 48) {
            // Bookmarks is a sidebar pane, so go *there* — the sidebar stays honest
            // about where you are. Learned isn't a pane, so it pushes, same as the
            // Learned row below.
            Button { pane = .bookmarks } label: {
                stat(t, model.bookmarks, model.bookmarks == 1 ? "bookmark" : "bookmarks") {
                    BookmarkRibbon(size: 12)
                }
            }
            .buttonStyle(.plain)
            .help("Show your bookmarks")

            NavigationLink {
                LearnedListView()
            } label: {
                stat(t, model.learned, model.learned == 1 ? "word learned" : "words learned") {
                    LearnedSeal(size: 14)
                }
            }
            .buttonStyle(.plain)
            .help("Show the words you've learned")
        }
    }

    /// How far through the 3,000-word mark you are, shown only if you asked for it
    /// in Settings. German only: the stat above counts every shelf, the goal
    /// counts the one shelf the 3,000 figure was measured on.
    private func goal(_ t: Theme) -> some View {
        let target = LearnedWords.fluencyGoal
        let learned = model.learnedGerman
        let left = target - learned
        let fraction = min(Double(learned) / Double(target), 1)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Toward German fluency")
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase).tracking(2)
                    .foregroundStyle(t.muted)
                Spacer(minLength: 8)
                Text("\(learned.formatted()) of \(target.formatted())")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(t.muted)
            }
            // A capsule pair rather than ProgressView: the stock bar brings its own
            // tint and corner radius, and neither matches the covers or the rules.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(t.ink.opacity(0.08))
                    Capsule().fill(t.accent)
                        .frame(width: max(geo.size.width * fraction, learned > 0 ? 4 : 0))
                }
            }
            .frame(height: 6)
            .animation(.snappy(duration: 0.3), value: fraction)
            Text(left > 0
                 ? "\(left.formatted()) to go \u{2014} experts put 3,000 German words at about 95% of everyday speech."
                 : "Past 3,000 \u{2014} the mark experts put at about 95% of everyday German.")
                .font(.system(size: 11))
                .foregroundStyle(t.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Toward German fluency. \(learned) of \(target) words.")
    }

    /// One big number under its glyph and caption. Two of them read as a pair,
    /// which is the whole reason this is a function and not two copied blocks.
    private func stat<Icon: View>(_ t: Theme, _ count: Int, _ label: String,
                                  @ViewBuilder icon: () -> Icon) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)")
                .font(doodle.face(64))
                .tracking(doodle.tracking(64))
                .foregroundStyle(t.ink)
                .contentTransition(.numericText())
            HStack(spacing: 6) {
                icon()
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase).tracking(2)
                    .foregroundStyle(t.muted)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Picture (edit mode only)

    /// The faces you can wear, shown rather than named — the same "pick the
    /// picture, not the word" idea as Settings' appearance tiles. A wrapping grid
    /// rather than a row: a dozen captioned tiles read as a form, a dozen faces
    /// read as a sheet of faces, which is what you're choosing from. The name is
    /// still there for the pointer and for VoiceOver.
    private func picture(_ t: Theme) -> some View {
        section("Picture", t, note: "The face in the sidebar corner too.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)],
                      alignment: .leading, spacing: 8) {
                ForEach(Avatar.allCases) { choice in
                    Button { draftAvatar = choice.rawValue } label: {
                        AvatarTile(avatar: choice,
                                   url: auth.photoURL,
                                   selected: choice.rawValue == draftAvatar,
                                   theme: t)
                    }
                    .buttonStyle(.plain)
                    .help(choice.name)
                    .accessibilityLabel(choice.name)
                    .accessibilityAddTraits(choice.rawValue == draftAvatar ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Details
    //
    // No card, no dividers, no dropdown: a muted label column and the facts beside
    // it, the way a dictionary sets an entry's grammar notes. A bordered card and
    // three hairlines around three short facts read louder than the facts did.

    private func details(_ t: Theme) -> some View {
        section("Details", t) {
            Grid(alignment: .leadingFirstTextBaseline,
                 horizontalSpacing: 24, verticalSpacing: 14) {
                GridRow {
                    label("Gender", t)
                    if editing {
                        genderChips(t)
                    } else {
                        value(Gender(rawValue: gender)?.name ?? Gender.unspecified.name, t)
                    }
                }
                // Read-only for good: the email is the account, and the join date is
                // Firebase's record of it. Neither is ours to rewrite.
                GridRow {
                    label("Email", t)
                    value(auth.email ?? "\u{2014}", t)
                }
                GridRow {
                    label("Member since", t)
                    value(auth.joined?.formatted(.dateTime.month(.wide).year()) ?? "\u{2014}", t)
                }
            }

            if let error = auth.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The choice shown as chips instead of hidden behind a dropdown — the same
    /// "pick the thing, don't unfold a menu" idea as the picture tiles above, and
    /// four options never justified a popup.
    private func genderChips(_ t: Theme) -> some View {
        HStack(spacing: 6) {
            ForEach(Gender.allCases) { choice in
                let on = choice.rawValue == draftGender
                Button { draftGender = choice.rawValue } label: {
                    Text(choice.name)
                        .font(.system(size: 12))
                        .foregroundStyle(on ? t.background : t.muted)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(on ? t.ink : .clear, in: Capsule())
                        .overlay(Capsule().strokeBorder(on ? .clear : t.hairline))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .animation(.snappy(duration: 0.16), value: draftGender)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gender")
    }

    // MARK: - Learned, settings & sign out

    /// Two rows, one idiom: Learned pushes a list, Settings switches pane. Settings
    /// is off the sidebar now, so this row is the way in.
    private func rows(_ t: Theme) -> some View {
        VStack(spacing: 8) {
            NavigationLink {
                LearnedListView()
            } label: {
                row(t, "Learned") { LearnedSeal(size: 16) }
            }
            .buttonStyle(.plain)

            Button { pane = .settings } label: {
                row(t, "Settings") {
                    // No hand-drawn gear in the set, so this one stays a symbol in
                    // both themes — GlyphIcon falls back on its own.
                    GlyphIcon(.settings, size: 15)
                        .foregroundStyle(t.muted)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func row<Icon: View>(_ t: Theme, _ title: String,
                                 @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 10) {
            icon()
                .frame(width: 16)
            Text(title)
                .font(.system(size: 13))
            Spacer(minLength: 6)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(t.muted)
        }
        .foregroundStyle(t.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(t.surface, in: RoundedRectangle(cornerRadius: t.radius(10)))
        .overlay(RoundedRectangle(cornerRadius: t.radius(10)).strokeBorder(t.hairline))
        .contentShape(Rectangle())
    }

    private func footer(_ t: Theme) -> some View {
        Button("Sign out") { auth.signOut() }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.5)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Pieces
    //
    // Same uppercase `section` label as SettingsView, so the two panes read as one
    // app. The rows below it are bare — Details has no switches to sit in a card.

    @ViewBuilder
    private func section<C: View>(_ title: String,
                                  _ t: Theme,
                                  note: String? = nil,
                                  @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase).tracking(2)
                .foregroundStyle(t.muted)
            content()
            if let note {
                Text(note)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
            }
        }
    }

    private func label(_ text: String, _ t: Theme) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(t.muted)
    }

    private func value(_ text: String, _ t: Theme) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(t.ink)
            .lineLimit(1)
            .truncationMode(.middle)   // a long email loses its middle, not its domain
    }
}

// MARK: - The face

/// One face at one size: the illustration you picked, or the account photo, or the
/// generic head when there is no photo (or it hasn't loaded). Draws what it's told
/// — the stored preference is `AccountAvatar`'s job, so the edit-mode tiles can
/// preview a choice that hasn't been saved yet.
struct AvatarFace: View {
    let avatar: Avatar
    let url: URL?
    let size: CGFloat
    let muted: Color

    var body: some View {
        Group {
            if let asset = avatar.asset {
                // 96pt source, so it's interpolated up on Retina at header sizes.
                // The illustrations are black line art on a transparent ground, so
                // they get a paper disc under them in *both* themes — on night black
                // the outlines would otherwise vanish into the background.
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .background(Color(hex: 0xF4F4F4))
            } else {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: size * 0.8))
                        .foregroundStyle(muted)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)   // the name beside it already says who this is
    }
}

/// The face wherever the app shows *you* — the Profile header and the sidebar
/// account chip — following whichever picture you chose in Profile.
struct AccountAvatar: View {
    let url: URL?
    let size: CGFloat
    let muted: Color
    @AppStorage("profileAvatar") private var avatar = Avatar.account.rawValue

    var body: some View {
        AvatarFace(avatar: Avatar(stored: avatar),
                   url: url, size: size, muted: muted)
    }
}

/// One choice in the picture picker: the face itself, ringed in ink when it's the
/// one you're on. No caption — the grid is read by looking, and the name rides on
/// `.help` and the accessibility label instead.
private struct AvatarTile: View {
    let avatar: Avatar
    let url: URL?
    let selected: Bool
    let theme: Theme

    var body: some View {
        AvatarFace(avatar: avatar, url: url, size: 46, muted: theme.muted)
            .overlay(Circle().strokeBorder(selected ? theme.ink : theme.hairline,
                                           lineWidth: selected ? 2 : 1))
            .padding(4)
            .background(selected ? theme.ink.opacity(0.06) : .clear, in: Circle())
            .contentShape(Circle())
    }
}

/// The learned mark: a filled green seal that carries its own colour, so nothing
/// here tints it. Same idea as BookmarkRibbon — the glyph is the state.
///
/// Already an illustration rather than a symbol, so the doodle theme doesn't
/// change its nature — only its hand, from the drawn seal to the drawn tick.
struct LearnedSeal: View {
    var size: CGFloat = 14
    @Environment(\.doodle) private var doodle

    var body: some View {
        if doodle.icons {
            Doodle("check_doodle", size: size)
        } else {
            Image("learned_icon").resizable().scaledToFit()
                .frame(width: size, height: size)
        }
    }
}

#Preview {
    NavigationStack { ProfileView(pane: .constant(.profile)) }
        .environment(AuthViewModel())
        .frame(width: 780, height: 720)
}
