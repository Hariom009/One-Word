//
//  Appearance.swift
//  OneWord
//
//  The app's light/dark preference. `.system` follows the Mac; light/dark force it.
//

import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
    
    /// The scheme to force, or nil to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
