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
//  On the Mac editing is in place rather than in a sheet: one pane, one Edit button,
//  and the header shows the draft as you type. A phone has no room to edit around
//  the stats and rows, so there Edit pushes EditProfileView instead. Either way
//  drafts only land on Save, so Cancel (or Back) really cancels.
//
//  Dumb view: the counts live in ProfileViewModel, the session in AuthViewModel,
//  and the editable fields — your photo too — in UserDefaults (see Profile.swift).
//

import SwiftUI
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named
import UniformTypeIdentifiers   // UTType.image, for the photo picker
import StoreKit   // manageSubscriptionsSheet — MEMBER_IMPORT_VISIBILITY needs it named

struct ProfileView: View {
    /// So the bookmark count can send you to the Bookmarks pane on the Mac rather
    /// than pushing a second copy of the same list on top of Profile.
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
    /// The goal counts only the German shelf, so it waits for German to unlock.
    @Environment(PremiumViewModel.self) private var premium

    /// iPhone and iPad: the plans as a sheet. The Mac opens their window instead.
    @State private var paywall = false
    @Environment(\.openWindow) private var openWindow
    /// The gold card's perks, folded until it's tapped.
    @State private var perksShown = false
    @State private var managing = false
    @Environment(\.openURL) private var openURL

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
                if premium.isUnlocked { premiumCard(t) } else { plans(t) }
                details(t)
                rows(t)
                if Features.accounts { footer(t) }
                version(t)
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
        .sheet(isPresented: $paywall) { PaywallView() }
        #if os(iOS)
        .manageSubscriptionsSheet(isPresented: $managing)
        #endif
    }

    /// The plans: their own window on the Mac, a sheet on iPhone and iPad.
    private func showPlans() {
        #if os(macOS)
        openWindow(id: PaywallView.windowID)
        #else
        paywall = true
        #endif
    }

    // MARK: - Header

    /// Face, name, email, and the one button that puts the pane into edit mode.
    /// A phone stacks the three in the middle, with Edit up in the strip.
    @ViewBuilder private func header(_ t: Theme) -> some View {
        if isPhone {
            VStack(spacing: 14) {
                AvatarFace(avatar: shownAvatar, url: auth.photoURL,
                           photo: photo, size: 96, muted: t.muted)
                    .overlay(Circle().strokeBorder(t.hairline))
                VStack(spacing: 4) {
                    nameLine(t).multilineTextAlignment(.center)
                    emailLine(t)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
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
        if isPhone {
            // Its own page on a phone, so the stats and Settings aren't in the way.
            NavigationLink { EditProfileView() } label: { capsuleLabel("Edit", t, filled: false) }
                .buttonStyle(.plain)
        } else if editing {
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
        Button(action: action) { capsuleLabel(title, t, filled: filled) }
            .buttonStyle(.plain)
    }

    // MARK: - Stats

    private func stats(_ t: Theme) -> some View {
        // Two bare figures a hand apart on the Mac; two tiles sharing the width on
        // a phone, where a figure with nothing around it reads as stray.
        HStack(alignment: .top, spacing: isPhone ? 0 : 48) {
            // Bookmarks is a sidebar pane on the Mac, so go *there* — the sidebar stays
            // honest about where you are. A phone pushes it onto Profile instead of
            // jumping tabs, so back returns here. Learned isn't a pane, so it pushes,
            // same as the Learned row below.
            let bookmarks = stat(t, model.bookmarks, model.bookmarks == 1 ? "bookmark" : "bookmarks") {
                BookmarkRibbon(size: 12)
            }
            Group {
                if isPhone {
                    NavigationLink { WordListView(wordbook: .saved) } label: { bookmarks }
                } else {
                    Button { pane = .bookmarks } label: { bookmarks }
                }
            }
            .buttonStyle(.plain)
            .help("Show your bookmarks")

            if isPhone { Rectangle().fill(t.hairline).frame(width: 1).padding(.vertical, 16) }

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
        .fixedSize(horizontal: false, vertical: true)   // so the rule spans the card
        .background { if isPhone { ProfileCard(t: t) } }
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
        let size: CGFloat = isPhone ? 36 : 64
        return VStack(alignment: isPhone ? .center : .leading, spacing: 4) {
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
        .frame(maxWidth: isPhone ? .infinity : nil)
        .padding(.vertical, isPhone ? 18 : 0)
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

    @ViewBuilder private func details(_ t: Theme) -> some View {
        if isPhone { phoneDetails(t) } else { wideDetails(t) }
    }

    /// The same facts as rows in one card, the way a phone lists settings-like facts.
    private func phoneDetails(_ t: Theme) -> some View {
        section("About you", t) {
            VStack(spacing: 0) {
                detailRow("Gender", Gender(rawValue: gender)?.name ?? Gender.unspecified.name, t)
                if Features.accounts {
                    Rectangle().fill(t.hairline).frame(height: 1).padding(.leading, 16)
                    detailRow("Member since",
                              auth.joined?.formatted(.dateTime.month(.wide).year()) ?? "\u{2014}", t)
                }
            }
            .background { ProfileCard(t: t) }

            if let error = auth.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func detailRow(_ title: String, _ value: String, _ t: Theme) -> some View {
        HStack {
            Text(title).foregroundStyle(t.muted)
            Spacer(minLength: 12)
            Text(value).foregroundStyle(t.ink).lineLimit(1)
        }
        .font(.system(size: 15))
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func wideDetails(_ t: Theme) -> some View {
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

    // MARK: - Plan

    /// Premium's colour in Profile: the owner's card is filled with it, the free reader's
    /// offer is edged with it, so the one reads as the other kept. Fixed on every
    /// appearance; `goldInk` on it is 7.2:1 at the dark end, 11.6:1 at the light.
    private static let gold = LinearGradient(colors: [Color(hex: 0xF6D77A), Color(hex: 0xD4A52C)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
    private static let goldInk = Color(hex: 0x2A1E05)

    /// A free reader's plan: Free, tagged as yours, then Premium on offer under it. The
    /// offer opens the paywall (all three plans). Restore stays — App Review wants one
    /// beside a non-consumable. An owner sees `premiumCard` instead.
    private func plans(_ t: Theme) -> some View {
        section("Plan", t, note: premium.problem) {
            VStack(spacing: 10) {
                freeCard(t)
                offerCard(t)
            }
        }
    }

    private func freeCard(_ t: Theme) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(t.muted)
                .frame(width: 34, height: 34)
                .background(t.ink.opacity(0.07), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Free")
                    .font(.system(size: isPhone ? 16 : 15, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text("A new word every day, from every dictionary.")
                    .font(.system(size: 13))
                    .foregroundStyle(t.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            PlanTag(text: "Current", filled: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { ProfileCard(t: t) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Free, your current plan")
    }

    private func offerCard(_ t: Theme) -> some View {
        let shape = RoundedRectangle(cornerRadius: t.radius(12))
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Self.goldInk)
                    .frame(width: 34, height: 34)
                    .background(Self.gold, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("One Word Premium")
                        .font(doodle.face(isPhone ? 21 : 20))
                        .tracking(doodle.tracking(20))
                        .foregroundStyle(t.ink)
                    Text(offerPrice)
                        .font(.system(size: 13))
                        .foregroundStyle(t.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 16) {
                Button { showPlans() } label: {
                    Text("See Plans")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Self.goldInk)
                        .padding(.horizontal, 18)
                        .frame(maxWidth: isPhone ? .infinity : nil, minHeight: isPhone ? 44 : 34)
                        .background(Self.gold, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows the monthly, yearly and lifetime plans")
                Button("Restore Purchase") { Task { await premium.restore() } }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(t.muted)
                    .disabled(premium.phase == .purchasing)
                if !isPhone { Spacer(minLength: 0) }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            shape.fill(t.surface)
                .overlay(shape.fill(Color(hex: 0xD4A52C).opacity(0.07)))
        }
        .overlay(shape.strokeBorder(Self.gold, lineWidth: 1.2))
    }

    /// The cheapest way in and the once-for-good one, as the App Store prices them here.
    private var offerPrice: String {
        if let monthly = premium.products[Premium.monthlyID], let lifetime = premium.product {
            return "From \(monthly.displayPrice) a month, or \(lifetime.displayPrice) once."
        }
        return "Monthly, yearly, or once for good."
    }

    /// An owner's plan: a gold card, the same on every appearance. Tapping it unfolds
    /// what Premium includes (PaywallView.perks — mock for now); a subscriber also gets
    /// Manage Subscription under it.
    private func premiumCard(_ t: Theme) -> some View {
        let ink = Self.goldInk
        let shape = RoundedRectangle(cornerRadius: t.radius(12))
        return section("Plan", t) {
            VStack(alignment: .leading, spacing: 12) {
                Button { withAnimation(.snappy) { perksShown.toggle() } } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Premium")
                                .font(.system(size: 11, weight: .bold))
                                .textCase(.uppercase).tracking(2)
                            Text("One Word Premium")
                                .font(doodle.face(22))
                                .tracking(doodle.tracking(22))
                            Text(premium.subscribed ? "Subscription" : "Lifetime")
                                .font(.system(size: 12))
                                .opacity(0.8)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .rotationEffect(.degrees(perksShown ? 90 : 0))
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("One Word Premium, \(premium.subscribed ? "subscription" : "lifetime")")
                .accessibilityValue(perksShown ? "Expanded" : "Collapsed")
                .accessibilityHint("Shows what Premium includes")
                .accessibilityAddTraits(.isButton)

                if perksShown {
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(PaywallView.perks, id: \.self) { perk in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .heavy))
                                    .padding(.top, 2)
                                    .accessibilityHidden(true)
                                Text(perk)
                                    .font(.system(size: 14))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if premium.subscribed {
                    Button("Manage Subscription") {
                        #if os(iOS)
                        managing = true
                        #else
                        // ponytail: the account page Apple documents for subscriptions; showManageSubscriptions is iOS-only.
                        openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                        #endif
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .underline()
                }
            }
            .foregroundStyle(ink)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                shape.fill(Self.gold)
                    .shadow(color: Color(hex: 0xD4A52C).opacity(0.35), radius: 14, y: 6)
            }
        }
    }

    // MARK: - Learned, settings & sign out

    /// Learned pushes a list, Settings switches pane. Settings is off the sidebar
    /// now, so this row is the way in. On a phone Learned lives only in the stats
    /// above, so its row is left off here.
    private func rows(_ t: Theme) -> some View {
        // Separate tiles on the Mac; one card with inset rules on a phone, the way
        // a phone groups a short list of ways onward.
        VStack(spacing: isPhone ? 0 : 8) {
            if !isPhone {
                NavigationLink {
                    LearnedListView()
                } label: {
                    row(t, "Learned") { LearnedSeal(size: 16) }
                }
                .buttonStyle(.plain)
            }

            if isPhone {
                // Bookmarks has no tab on a phone (RootView.tabOrder), so it gets a row here.
                NavigationLink { WordListView(wordbook: .saved) } label: {
                    row(t, "Bookmarks") {
                        GlyphIcon(.bookmarks, size: 15).foregroundStyle(t.muted)
                    }
                }
                .buttonStyle(.plain)
                separator(t)
            }

            Button { pane = .settings } label: {
                row(t, "Settings") {
                    GlyphIcon(.settings, size: 15)
                        .foregroundStyle(t.muted)
                }
            }
            .buttonStyle(.plain)
        }
        .background { if isPhone { ProfileCard(t: t) } }
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

    @ViewBuilder private func footer(_ t: Theme) -> some View {
        if isPhone {
            // A row of its own, last, like every phone's sign-out.
            Button { auth.signOut() } label: {
                Text("Sign Out")
                    .font(.system(size: 15))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background { ProfileCard(t: t) }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Button("Sign out") { auth.signOut() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
        }
    }

    /// The app's version and build, last on the pane. Same source as the feedback
    /// trailer, so a bug report and this line name the same build.
    private func version(_ t: Theme) -> some View {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return Text("Version \(short) (\(build))")
            .font(.system(size: 11))
            .foregroundStyle(t.muted)
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

/// The Edit / Cancel / Save pill — EditProfileView's Save wears it too.
func capsuleLabel(_ title: String, _ t: Theme, filled: Bool) -> some View {
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

/// The phone's grouped card: Profile's stats, facts and rows, and Edit Profile's fields.
struct ProfileCard: View {
    let t: Theme
    var body: some View {
        RoundedRectangle(cornerRadius: t.radius(12)).fill(t.surface)
            .overlay(RoundedRectangle(cornerRadius: t.radius(12)).strokeBorder(t.hairline))
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
struct AvatarTile: View {
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
struct LearnedSeal: View {
    var size: CGFloat = 14

    var body: some View {
        Image("learned_icon").resizable().scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview {
    NavigationStack { ProfileView(pane: .constant(.profile)) }
        .environment(AuthViewModel())
        .environment(PremiumViewModel())
        .frame(width: 780, height: 720)
}
