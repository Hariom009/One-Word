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
    // One index for the whole navigation stack — every WordDetail in a chain
    // serves itself from this store via the environment.
    @State private var relatedWords = RelatedWordsStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WordView()
            }
            .environment(relatedWords)
            .preferredColorScheme((Appearance(rawValue: appearance) ?? .system).colorScheme)
        }
    }
}
