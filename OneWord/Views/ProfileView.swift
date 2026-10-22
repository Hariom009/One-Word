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
//  and the editable fields — your photo too — in UserDefaults (see Profile.swift).
//

import SwiftUI
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named
import UniformTypeIdentifiers   // UTType.image, for the photo picker

struct ProfileView: View {
    /// So the bookmark count can send you to the Bookmarks pane rather than
    /// pushing a second copy of the same list on top of Profile.
    @Binding var pane: Pane
    @Environment(\.colorScheme) private var scheme

    @State private var model = ProfileViewModel()
    // Owned by the app so the sidebar chip shows the same user. RootView restores it.
    @Environment(AuthViewModel.self) private var auth

    // Yours to set. The account owns the email and the join date; these three are ours.
    @AppStorage("profileName") private var name = ""
    @AppStorage("profileGender") private var gender = Gender.unspecified.rawValue
    @AppStorage("profileAvatar") private var avatar = Avatar.account.rawValue
    /// Your own picture, already shrunk to avatar size. Worn when `avatar` is `.photo`.
    @AppStorage("profilePhoto") private var photo: Data?
    /// Set in Settings. Off, the raw count above is the whole story.
    @AppStorage("fluencyGoal") private var fluencyGoal = false
    /// Settings can hide Practice; on a phone that hides its row here.
    @AppStorage("practiceEnabled") private var practiceEnabled = true
    /// The goal counts only the German shelf, so it waits for German to unlock.
    @Environment(PremiumViewModel.self) private var premium

    @State private var editing = false
    @State private var draftName = ""
    @State private var draftGender = Gender.unspecified.rawValue
    @State private var draftAvatar = Avatar.account.rawValue
    @State private var draftPhoto: Data?
    @State private var choosingPhoto = false
    @State private var photoUnreadable = false

    /// What to call you: your own name if you set one, else the one the account gave.
    private var shownName: String {
        name.isEmpty ? (auth.displayName ?? (Features.accounts ? "Signed in" : "You")) : name
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
            VStack(alignment: .leading, spacing: isPhone ? 28 : 30) {
                header(t)
                if editing { picture(t) }
                stats(t)
                if fluencyGoal && premium.allows(Wordbook.german.id) { goal(t) }
                details(t)
                rows(t)
                if Features.accounts { footer(t) }
            }
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, isPhone ? 20 : 24)
            .padding(.vertical, isPhone ? 12 : 24)
        }
        .paneBackground(t)
        // On a phone the face and name are centred under the strip, so Edit moves
        // up into the strip's corner where a phone keeps it.
        .paneHeader("Profile") { if isPhone { editControls(t) } }
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
    /// A phone stacks the three in the middle, with Edit up in the strip.
    @ViewBuilder private func header(_ t: Theme) -> some View {
        if isPhone {
            VStack(spacing: 14) {
                AvatarFace(avatar: shownAvatar, url: auth.photoURL,
                           photo: editing ? draftPhoto : photo, size: 92, muted: t.muted)
                    .overlay(Circle().strokeBorder(t.hairline))
                VStack(spacing: 4) {
                    nameLine(t).multilineTextAlignment(.center)
                    emailLine(t)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        } else {
            HStack(alignment: .center, spacing: 18) {
                AvatarFace(avatar: shownAvatar, url: auth.photoURL,
                           photo: editing ? draftPhoto : photo, size: 76, muted: t.muted)
                    .overlay(Circle().strokeBorder(t.hairline))

                VStack(alignment: .leading, spacing: 5) {
                    nameLine(t)
                    emailLine(t)
                }

                Spacer(minLength: 8)
                editControls(t)
            }
        }
    }

    @ViewBuilder private func nameLine(_ t: Theme) -> some View {
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
    }

    @ViewBuilder private func emailLine(_ t: Theme) -> some View {
        if let email = auth.email {
            Text(email)
                .font(.system(size: 12))
                .foregroundStyle(t.muted)
                .lineLimit(1)
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
                draftPhoto = photo
                photoUnreadable = false
                editing = true
            }
        }
    }

    private func save() {
        // Blank means "go back to following the account", not a blank name.
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        name = trimmed == (auth.displayName ?? "") ? "" : trimmed
        gender = draftGender
        avatar = draftAvatar
        photo = draftPhoto
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
        // Two bare figures a hand apart on the Mac; two tiles sharing the width on
        // a phone, where a figure with nothing around it reads as stray.
        HStack(alignment: .top, spacing: isPhone ? 12 : 48) {
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
        let size: CGFloat = isPhone ? 40 : 64
        return VStack(alignment: .leading, spacing: 4) {
            Text("\(count)")
                .font(doodle.face(size))
                .tracking(doodle.tracking(size))
                .foregroundStyle(t.ink)
                .contentTransition(.numericText())
            HStack(spacing: 6) {
                icon()
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase).tracking(isPhone ? 1.4 : 2)
                    .foregroundStyle(t.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: isPhone ? .infinity : nil, alignment: .leading)
        .padding(isPhone ? 16 : 0)
        .background { if isPhone { RoundedRectangle(cornerRadius: t.radius(12)).fill(t.surface) } }
        .overlay { if isPhone { RoundedRectangle(cornerRadius: t.radius(12)).strokeBorder(t.hairline) } }
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
        section("Picture", t, note: photoUnreadable
                ? "That file couldn't be read as a picture."
                : "The face in the sidebar corner too.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)],
                      alignment: .leading, spacing: 8) {
                ForEach(Avatar.allCases) { choice in
                    let empty = choice == .photo && draftPhoto == nil
                    Button { pick(choice) } label: {
                        AvatarTile(avatar: choice,
                                   url: auth.photoURL,
                                   photo: draftPhoto,
                                   selected: choice.rawValue == draftAvatar,
                                   theme: t)
                    }
                    .buttonStyle(.plain)
                    .help(empty ? "Choose a photo\u{2026}" : choice.name)
                    .accessibilityLabel(empty ? "Choose a photo" : choice.name)
                    .accessibilityAddTraits(choice.rawValue == draftAvatar ? .isSelected : [])
                    .contextMenu {
                        if choice == .photo && !empty {
                            Button("Choose Another Photo\u{2026}") { choosingPhoto = true }
                            Button("Remove Photo", role: .destructive, action: removePhoto)
                        }
                    }
                }
            }
        }
        .fileImporter(isPresented: $choosingPhoto, allowedContentTypes: [.image]) { result in
            guard case .success(let url) = result else { return }   // cancelled
            if let data = ProfileViewModel.photo(from: url) {
                draftPhoto = data
                draftAvatar = Avatar.photo.rawValue
                photoUnreadable = false
            } else {
                photoUnreadable = true
            }
        }
    }

    /// Your photo's tile is also the way to change it: empty, or clicked again once
    /// it's the face you're wearing, it opens the file picker.
    private func pick(_ choice: Avatar) {
        if choice == .photo && (draftPhoto == nil || draftAvatar == choice.rawValue) {
            choosingPhoto = true
        } else {
            draftAvatar = choice.rawValue
        }
    }

    /// Like every edit here, it only lands on Save.
    private func removePhoto() {
        draftPhoto = nil
        if draftAvatar == Avatar.photo.rawValue { draftAvatar = Avatar.account.rawValue }
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
                // Firebase's record of it. Neither is ours to rewrite. The phone's
                // header already shows the email under the name, so there it's not
                // said twice.
                if Features.accounts {
                    if !isPhone {
                        GridRow {
                            label("Email", t)
                            value(auth.email ?? "\u{2014}", t)
                        }
                    }
                    GridRow {
                        label("Member since", t)
                        value(auth.joined?.formatted(.dateTime.month(.wide).year()) ?? "\u{2014}", t)
                    }
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
    /// is off the sidebar now, so this row is the way in. A phone has no sidebar
    /// at all, so Practice and the plan tag get rows here too.
    private func rows(_ t: Theme) -> some View {
        // Separate tiles on the Mac; one card with inset rules on a phone, the way
        // a phone groups a short list of ways onward.
        VStack(spacing: isPhone ? 0 : 8) {
            NavigationLink {
                LearnedListView()
            } label: {
                row(t, "Learned") { LearnedSeal(size: 16) }
            }
            .buttonStyle(.plain)

            if isPhone {
                // The tab bar's third slot is Practice once it's owned and on, Bookmarks
                // until then (RootView.tabOrder) — so the row here is whichever one has no tab.
                if premium.isUnlocked && practiceEnabled {
                    separator(t)
                    Button { pane = .bookmarks } label: {
                        row(t, "Bookmarks") {
                            GlyphIcon(.bookmarks, size: 15).foregroundStyle(t.muted)
                        }
                    }
                    .buttonStyle(.plain)
                } else if practiceEnabled {
                    separator(t)
                    // The shell gates it: locked, the row lands on the plans.
                    Button { pane = .practice } label: {
                        row(t, "Practice") {
                            GlyphIcon(.practice, size: 15).foregroundStyle(t.muted)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue("Premium")
                }
                separator(t)
                Button { pane = .premium } label: {
                    row(t, premium.isUnlocked ? "Premium" : "Free plan") {
                        GlyphIcon(.premium, size: 15).foregroundStyle(t.muted)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows the plans")
                separator(t)
            }

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
        .background { if isPhone { RoundedRectangle(cornerRadius: t.radius(12)).fill(t.surface) } }
        .overlay { if isPhone { RoundedRectangle(cornerRadius: t.radius(12)).strokeBorder(t.hairline) } }
    }

    /// The rule between two rows of the phone's card, inset past the icon column.
    private func separator(_ t: Theme) -> some View {
        Rectangle().fill(t.hairline).frame(height: 1).padding(.leading, 42)
    }

    private func row<Icon: View>(_ t: Theme, _ title: String,
                                 @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 10) {
            icon()
                .frame(width: 16)
            Text(title)
                .font(.system(size: isPhone ? 15 : 13))
            Spacer(minLength: 6)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(t.muted)
        }
        .foregroundStyle(t.ink)
        .padding(.horizontal, isPhone ? 16 : 14)
        .padding(.vertical, isPhone ? 14 : 11)
        .background { if !isPhone { RoundedRectangle(cornerRadius: t.radius(10)).fill(t.surface) } }
        .overlay { if !isPhone { RoundedRectangle(cornerRadius: t.radius(10)).strokeBorder(t.hairline) } }
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
    /// Your own picture's JPEG bytes — drawn only when `avatar` is `.photo`.
    let photo: Data?
    let size: CGFloat
    let muted: Color

    var body: some View {
        Group {
            if avatar == .photo {
                // ponytail: decoded per render. It's a ≤512px JPEG; cache the
                // NSImage if this ever shows up in a profile.
                if let photo, let image = Self.image(photo) {
                    image
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                } else {
                    head
                }
            } else if let asset = avatar.asset {
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
                    head
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)   // the name beside it already says who this is
    }

    private static func image(_ data: Data) -> Image? {
        #if os(macOS)
        NSImage(data: data).map(Image.init(nsImage:))
        #else
        UIImage(data: data).map(Image.init(uiImage:))
        #endif
    }

    /// The generic head, for a face with no picture behind it yet.
    private var head: some View {
        Image(systemName: "person.crop.circle")
            .font(.system(size: size * 0.8))
            .foregroundStyle(muted)
    }
}

/// The face wherever the app shows *you* — the Profile header and the sidebar
/// account chip — following whichever picture you chose in Profile.
struct AccountAvatar: View {
    let url: URL?
    let size: CGFloat
    let muted: Color
    @AppStorage("profileAvatar") private var avatar = Avatar.account.rawValue
    @AppStorage("profilePhoto") private var photo: Data?

    var body: some View {
        AvatarFace(avatar: Avatar(stored: avatar),
                   url: url, photo: photo, size: size, muted: muted)
    }
}

/// One choice in the picture picker: the face itself, ringed in ink when it's the
/// one you're on. No caption — the grid is read by looking, and the name rides on
/// `.help` and the accessibility label instead.
private struct AvatarTile: View {
    let avatar: Avatar
    let url: URL?
    let photo: Data?
    let selected: Bool
    let theme: Theme

    var body: some View {
        Group {
            if avatar == .photo && photo == nil {
                // Nothing picked yet: the tile is an invitation, not a face.
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.muted)
                    .frame(width: 46, height: 46)
            } else {
                AvatarFace(avatar: avatar, url: url, photo: photo, size: 46, muted: theme.muted)
            }
        }
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
        .environment(PremiumViewModel())
        .frame(width: 780, height: 720)
}
