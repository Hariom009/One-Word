//
//  Appearance.swift
//  OneWord
//
//  The app's appearance preference. `.system` follows the device's light or dark.
//  `.midnight` is a palette as well as a scheme: it forces dark and repaints the
//  app with its own ground and accent (Theme.midnight). `.umber` is the same kind of thing built the opposite way: warm,
//  flat and serif where Midnight is cool, lit and sans (Theme.umber).
//

import SwiftUI

/// nonisolated: a plain value, and `DoodleTheme.current` reads it off the main actor.
nonisolated enum Appearance: String, CaseIterable, Identifiable {
    case system, midnight, umber

    /// What a fresh install, a missing key or an unknown string resolves to.
    static let initial = Appearance.midnight

    var id: String { rawValue }

    /// The stored string, parsed. "light" and "dark" were their own appearances once;
    /// they read as System now, which covers both, rather than jumping to Midnight.
    static func stored(_ raw: String?) -> Appearance {
        switch raw {
        case "light", "dark": return .system
        default:              return raw.flatMap(Appearance.init(rawValue:)) ?? .initial
        }
    }

    var name: String {
        switch self {
        case .system:   return "System"
        case .midnight: return "Midnight"
        case .umber:    return "Umber"
        }
    }

    /// The scheme to force, or nil to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system:           return nil
        case .midnight, .umber: return .dark
        }
    }

    /// True for an appearance that brings a palette of its own rather than following
    /// the scheme. The shell asks this — not "is it Midnight?" — before tinting the
    /// stock controls and painting through the sidebar. No `default`: a new case has
    /// to answer here before it compiles.
    var paintsPalette: Bool {
        switch self {
        case .system:           return false
        case .midnight, .umber: return true
        }
    }
}
