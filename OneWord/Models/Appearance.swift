//
//  Appearance.swift
//  OneWord
//
//  The app's appearance preference. `.system` follows the Mac; light/dark force it.
//  `.midnight` is a palette as well as a scheme: it forces dark and repaints the
//  app navy (Theme.midnight). It sits beside light and dark rather than being a
//  switch of its own because it can't be combined with either of them.
//

import SwiftUI

/// nonisolated: a plain value, and `DoodleTheme.current` reads it off the main actor.
nonisolated enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark, midnight

    var id: String { rawValue }

    var name: String {
        switch self {
        case .system:   return "System"
        case .light:    return "Light"
        case .dark:     return "Dark"
        case .midnight: return "Midnight"
        }
    }

    /// The scheme to force, or nil to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system:          return nil
        case .light:           return .light
        case .dark, .midnight: return .dark
        }
    }
}
