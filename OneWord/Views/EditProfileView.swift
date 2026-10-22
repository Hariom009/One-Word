//
//  EditProfileView.swift
//  OneWord
//
//  The phone's Edit Profile page, pushed from Profile's Edit. Only the things you
//  can change — face, name, gender — so the stats, rows and Settings aren't
//  sitting around the fields. Drafts land on Save; Back throws them away.
//
//  The Mac edits in place on ProfileView instead (see its header note).
//

import SwiftUI
import UniformTypeIdentifiers   // UTType.image, for the photo picker

struct EditProfileView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var auth

    // Same keys as ProfileView and AccountAvatar — see Profile.swift.
    @AppStorage("profileName") private var name = ""
    @AppStorage("profileGender") private var gender = Gender.unspecified.rawValue
    @AppStorage("profileAvatar") private var avatar = Avatar.account.rawValue
    @AppStorage("profilePhoto") private var photo: Data?

    @State private var draftName = ""
    @State private var draftGender = Gender.unspecified.rawValue
    @State private var draftAvatar = Avatar.account.rawValue
    @State private var draftPhoto: Data?
    @State private var loaded = false
    @State private var choosingPhoto = false
    @State private var photoUnreadable = false

    var body: some View {
        let t = Theme.of(scheme, doodle)
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                face(t)
                section("Name", t) {
                    TextField("Your name", text: $draftName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundStyle(t.ink)
                        .submitLabel(.done)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background { ProfileCard(t: t) }
                }
                section("Picture", t) { pictures(t) }
                section("Gender", t) { genders(t) }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .paneBackground(t)
        .paneHeader("Edit Profile", back: true) {
            Button(action: save) { capsuleLabel("Save", t, filled: true) }
                .buttonStyle(.plain)
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
        .onAppear {
            // Once: coming back from the file picker must not reset the drafts.
            guard !loaded else { return }
            loaded = true
            draftName = name.isEmpty ? (auth.displayName ?? "") : name
            draftGender = gender
            draftAvatar = avatar
            draftPhoto = photo
        }
    }

    /// The face as it will be saved, with the photo controls under it.
    private func face(_ t: Theme) -> some View {
        VStack(spacing: 12) {
            AvatarFace(avatar: Avatar(stored: draftAvatar), url: auth.photoURL,
                       photo: draftPhoto, size: 96, muted: t.muted)
                .overlay(Circle().strokeBorder(t.hairline))
            HStack(spacing: 18) {
                Button(draftPhoto == nil ? "Choose Photo" : "Change Photo") { choosingPhoto = true }
                    .foregroundStyle(t.accent)
                if draftPhoto != nil {
                    Button("Remove", role: .destructive, action: removePhoto)
                        .foregroundStyle(.red)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .medium))
            if photoUnreadable {
                Text("That file couldn't be read as a picture.")
                    .font(.system(size: 12))
                    .foregroundStyle(t.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.snappy(duration: 0.2), value: draftAvatar)
    }

    private func pictures(_ t: Theme) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 8)], spacing: 8) {
            ForEach(Avatar.allCases) { choice in
                let empty = choice == .photo && draftPhoto == nil
                Button { pick(choice) } label: {
                    AvatarTile(avatar: choice, url: auth.photoURL, photo: draftPhoto,
                               selected: choice.rawValue == draftAvatar, theme: t)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(empty ? "Choose a photo" : choice.name)
                .accessibilityAddTraits(choice.rawValue == draftAvatar ? .isSelected : [])
            }
        }
        .padding(12)
        .background { ProfileCard(t: t) }
    }

    /// Four equal segments in one track — a segmented control in the app's colours.
    private func genders(_ t: Theme) -> some View {
        HStack(spacing: 4) {
            ForEach(Gender.allCases) { choice in
                let on = choice.rawValue == draftGender
                Button { draftGender = choice.rawValue } label: {
                    Text(choice.name)
                        .font(.system(size: 14, weight: on ? .semibold : .regular))
                        .foregroundStyle(on ? t.background : t.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(on ? t.ink : .clear, in: RoundedRectangle(cornerRadius: t.radius(8)))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .background { ProfileCard(t: t) }
        .animation(.snappy(duration: 0.16), value: draftGender)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gender")
    }

    private func section<C: View>(_ title: String, _ t: Theme,
                                  @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase).tracking(2)
                .foregroundStyle(t.muted)
            content()
        }
    }

    /// The photo tile picks your photo, or opens the picker when there isn't one yet.
    private func pick(_ choice: Avatar) {
        if choice == .photo && draftPhoto == nil {
            choosingPhoto = true
        } else {
            draftAvatar = choice.rawValue
        }
    }

    private func removePhoto() {
        draftPhoto = nil
        if draftAvatar == Avatar.photo.rawValue { draftAvatar = Avatar.account.rawValue }
    }

    private func save() {
        // Blank means "go back to following the account", not a blank name — as on the Mac.
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        name = trimmed == (auth.displayName ?? "") ? "" : trimmed
        gender = draftGender
        avatar = draftAvatar
        photo = draftPhoto
        dismiss()
    }
}
