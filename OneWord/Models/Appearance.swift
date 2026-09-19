//
//  Appearance.swift
//  OneWord
//
//  The app's appearance preference. `.system` follows the Mac; light/dark force it.
//  `.midnight` is a palette as well as a scheme: it forces dark and repaints the
//  app with its own ground and accent (Theme.midnight). It sits beside light and
//  dark rather than being a switch of its own because it can't be combined with
//  either of them. `.umber` is the same kind of thing built the opposite way: warm,
//  flat and serif where Midnight is cool, lit and sans (Theme.umber).
//

import SwiftUI

/// nonisolated: a plain value, and `DoodleTheme.current` reads it off the main actor.
nonisolated enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark, midnight, umber

    var id: String { rawValue }

    var name: String {
        switch self {
        case .system:   return "System"
        case .light:    return "Light"
        case .dark:     return "Dark"
        case .midnight: return "Midnight"
        case .umber:    return "Umber"
        }
    }

    /// The scheme to force, or nil to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system:                  return nil
        case .light:                   return .light
        case .dark, .midnight, .umber: return .dark
        }
    }

    /// True for an appearance that brings a palette of its own rather than following
    /// the scheme. The shell asks this — not "is it Midnight?" — before tinting the
    /// stock controls and painting through the sidebar. No `default`: a new case has
    /// to answer here before it compiles.
    var paintsPalette: Bool {
        switch self {
        case .system, .light, .dark: return false
        case .midnight, .umber:      return true
        }
    }
}
