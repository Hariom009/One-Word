//
//  OneWordApp.swift
//  OneWord
//
//  Created by Hari's Mac on 23.07.2026.
//

import SwiftUI
import WidgetKit

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
    // One store for the whole window: the shelf, search, the word page and Settings all
    // ask it what's unlocked, and it tells the widget through the App Group.
    @State private var premium = PremiumViewModel()

    /// The stored string, parsed once. A missing or unknown value is System.
    private var look: Appearance { Appearance(rawValue: appearance) ?? .system }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(relatedWords)
                .environment(auth)
                .environment(premium)
                // The appearance rides the same value: it can change the face as well as
                // the palette, and `face()` is the one place the face is decided.
                .environment(\.doodle, DoodleTheme(icons: doodleIcons, handwriting: doodleFont,
                                                   appearance: look))
                .preferredColorScheme(look.colorScheme)
                .task { await premium.load() }
                // The widget reads the unlock from the App Group; tell it to look again.
                .onChange(of: premium.isUnlocked) { WidgetCenter.shared.reloadAllTimelines() }
        }
        .defaultSize(width: 1000, height: 680)
        // Title bar hidden, traffic lights kept: every pane draws its own header,
        // and RootView switches the window's toolbar off.
        .windowStyle(.hiddenTitleBar)
    }
}
