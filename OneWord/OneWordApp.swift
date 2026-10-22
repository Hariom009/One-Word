//
//  OneWordApp.swift
//  OneWord
//
//  Created by Hari's Mac on 23.07.2026.
//

import SwiftUI
import WidgetKit
import FirebaseCore
import GoogleSignIn
#if os(iOS)
import AVFoundation
#endif

@main
struct OneWordApp: App {
    #if os(macOS)
    // Registers the Services provider so "Save to One Word" works from any app.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    #endif
    @AppStorage("appearance") private var appearance = Appearance.initial.rawValue
    // The doodle theme's two switches, read HERE and nowhere else: a view that
    // asked UserDefaults directly would draw the right thing once and then never
    // hear the switch flip. Down the environment, every pane redraws together.
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

    /// The stored string, parsed once.
    private var look: Appearance { .stored(appearance) }

    /// Firebase here, not in an app delegate: on macOS the window's views appear before
    /// applicationDidFinishLaunching fires, so RootView's `auth.restore()` asked Firebase
    /// for the app first, found none, and every launch opened on the sign-in screen with
    /// the keychain session ignored. The App's init runs before any scene on both platforms.
    init() {
        #if DEBUG
        // Scheme argument: wipe the front-door flag so a debug run starts on Get
        // Started and the button still works (a `-onboarded NO` argument would
        // outrank the write and leave the button stuck).
        if CommandLine.arguments.contains("--reset-onboarding") {
            UserDefaults.standard.removeObject(forKey: WelcomeView.onboardedKey)
        }
        #endif
        if Features.accounts { Self.configureFirebase() }
        CloudSync.start()
        #if os(iOS)
        // The default category, .soloAmbient, stops the user's music the moment the shelf
        // clicks or the roll shuffles, and .ambient is muted outright by Silent mode —
        // which the Action button toggles, so a tap on Pronounce produced nothing.
        // Playback ignores Silent mode; mixWithOthers keeps the user's music going.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        #endif
    }

    /// Reads GoogleService-Info.plist from the bundle, then wires GoogleSignIn by hand.
    ///
    /// GIDSignIn does NOT read GoogleService-Info.plist — its only self-configuration
    /// path is a GIDClientID key in Info.plist (GIDSignIn.m:1351), and an unconfigured
    /// interactive signIn raises NSInvalidArgumentException (:723): a crash, not an
    /// error you can catch. Handing it the id off FirebaseApp keeps
    /// GoogleService-Info.plist the one place the client id lives.
    private static func configureFirebase() {
        FirebaseApp.configure()
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            assertionFailure("No CLIENT_ID in GoogleService-Info.plist — sign-in would crash.")
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(relatedWords)
                .environment(auth)
                .environment(premium)
                // The appearance rides the same value: it can change the face as well as
                // the palette, and `face()` is the one place the face is decided.
                .environment(\.doodle, DoodleTheme(handwriting: doodleFont,
                                                   appearance: look))
                .preferredColorScheme(look.colorScheme)
                // Premium belongs to the App Store's Apple ID, not a sign-in: no one to wait for.
                .task { if Features.premium { await premium.load() } }
                // The widget reads the unlock from the App Group; tell it to look again.
                .onChange(of: premium.isUnlocked) { WidgetCenter.shared.reloadAllTimelines() }
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 680)
        // Title bar hidden, traffic lights kept: every pane draws its own header,
        // and RootView switches the window's toolbar off.
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
