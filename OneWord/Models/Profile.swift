//
//  Profile.swift
//  OneWord
//
//  The parts of "who you are" that Google doesn't hand us. The account owns the
//  email and the join date — those are read-only for good. The name you'd rather
//  be called, your gender and which face to show are yours to set.
//
//  ponytail: plain UserDefaults via @AppStorage at the two call sites that care
//  (the Profile pane and the sidebar chip), exactly like `appearance`. Nothing
//  here is pushed back to Firebase — it's a local preference, not an account
//  change, so there's no network call and nothing to fail. Swap in
//  `createProfileChangeRequest()` if the name ever has to follow you to another Mac.
//

import SwiftUI

enum Gender: String, CaseIterable, Identifiable {
    case female, male, other, unspecified

    var id: String { rawValue }

    var name: String {
        switch self {
        case .unspecified: return "Not set"
        case .female:      return "Female"
        case .male:        return "Male"
        case .other:       return "Other"
        }
    }
}

/// Which face the avatar wears. `.account` is the photo on the signed-in account —
/// the default, and the only one that can come up empty (not every account has one,
/// which is what the generic head is for). Never named after the provider: the app
/// says "Account", not whose account.
enum Avatar: String, CaseIterable, Identifiable {
    case account, female, male, boy, redhead, businesswoman, woman, man,
         walter, simpson, alien, dog, pumpkin

    var id: String { rawValue }

    /// Reads a stored preference, including the older `"google"` spelling, which
    /// meant this same option. Saves the migration a defaults-rewrite would cost.
    init(stored: String) { self = Avatar(rawValue: stored) ?? .account }

    var name: String { face.name }

    /// The asset to draw, or nil for `.account` — which loads the account photo.
    var asset: String? { face.asset }

    /// One table rather than two switches: a new face is a case above and a row
    /// here, and the name can never drift from the picture it labels.
    private var face: (name: String, asset: String?) {
        switch self {
        case .account:       return ("Account", nil)
        case .female:        return ("Female", "female_profile_icon")
        case .male:          return ("Male", "male_profile_icon")
        case .boy:           return ("Boy", "boy_profile")
        case .redhead:       return ("Redhead", "redhead_profile")
        case .businesswoman: return ("Businesswoman", "businesswoman_profile")
        case .woman:         return ("Woman", "mature_woman_profile")
        case .man:           return ("Man", "black_male_profile")
        case .walter:        return ("Walter", "walter_profile")
        case .simpson:       return ("Simpson", "simpson_profile")
        case .alien:         return ("Alien", "alient_profile")   // the typo is the asset's
        case .dog:           return ("Dog", "dog_profile")
        case .pumpkin:       return ("Pumpkin", "pumpkin_profile")
        }
    }
}
