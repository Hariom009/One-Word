//
//  OneWordApp.swift
//  OneWord
//
//  Created by Hari's Mac on 23.07.2026.
//

import SwiftUI

@main
struct OneWordApp: App {
    // Registers the Services provider so "Save to One Word" works from any app.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    // The doodle theme's two switches, read HERE and nowhere else: a view that
    // asked UserDefaults directly would draw the right thing once and then never
    // hear the switch flip. Down the environment, every pane redraws together.
    @AppStorage(DoodleTheme.iconsKey) private var doodleIcons = false
    @AppStorage(DoodleTheme.handwritingKey) private var doodleFont = false
    // One index for the whole navigation stack — every WordDetail in a chain
    // serves itself from this store via the environment.
    @State private var relatedWords = RelatedWordsStore()
    // One session for the whole window: the sidebar chip and the Profile pane
    // read the same signed-in user rather than each owning a copy.
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(relatedWords)
                .environment(auth)
                .environment(\.doodle, DoodleTheme(icons: doodleIcons, handwriting: doodleFont))
                .preferredColorScheme((Appearance(rawValue: appearance) ?? .system).colorScheme)
        }
        .defaultSize(width: 1000, height: 680)
    }
}
