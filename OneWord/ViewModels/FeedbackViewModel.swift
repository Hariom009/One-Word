//
//  FeedbackViewModel.swift
//  OneWord
//
//  Sending a complaint. The email path needs no state — a mailto URL handed to
//  LaunchServices is the whole feature — so this type is really the notepad: the
//  draft, and the one POST that files it.
//
//  App target ONLY, same rule as AuthViewModel: it names FirebaseAuth.User to get
//  an ID token, and Shared/ compiles into the widget and into tools/check_*.sh with
//  bare swiftc, neither of which links Firebase.
//

import Foundation
import Observation
import FirebaseCore
import FirebaseAuth

@Observable
final class FeedbackViewModel {

    // MARK: - Where it goes

    /// Where complaints go when they go by mail. One place, because the sheet's
    /// failure copy names the same address.
    static let address = "hi.hariom.swift@gmail.com"

    /// A pre-addressed draft in whatever the Mac's mail client is. Version and OS
    /// ride along because the first reply to any bug report is "which build?" —
    /// and unlike the in-app path, an email carries no metadata otherwise.
    ///
    /// ponytail: NSWorkspace.open, not NSSharingService. The sandbox permits it —
    /// LaunchServices opens the URL in another process — so no entitlement changes.
    static var mailtoURL: URL? {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let trailer = "\n\n\u{2014}\nOne Word \(version) (\(build))\n"
                    + ProcessInfo.processInfo.operatingSystemVersionString

        // Newlines and spaces are illegal in a URL. Without this the string fails
        // to parse, URL(string:) returns nil, and the button silently does nothing.
        // `.urlQueryAllowed` leaves & and = alone — fine, because neither the
        // subject nor the trailer contains either. Keep it that way if you edit them.
        let q = CharacterSet.urlQueryAllowed
        guard let subject = "One Word feedback".addingPercentEncoding(withAllowedCharacters: q),
              let body = trailer.addingPercentEncoding(withAllowedCharacters: q)
        else { return nil }
        return URL(string: "mailto:\(address)?subject=\(subject)&body=\(body)")
    }

    // MARK: - The draft

    /// The draft. It lives here rather than in the sheet so a failed send keeps the
    /// text — the view redraws, the words don't go anywhere.
    var text = ""

    private(set) var sending = false
    private(set) var error: String?
    /// Set once the POST lands. The sheet swaps to the thank-you on this.
    private(set) var sent = false

    /// What the counter counts.
    static let limit = 4000
    /// What the server ceiling actually is about. Devanagari costs up to 3 UTF-8
    /// bytes per scalar and a Swift Character can be several scalars, so a message
    /// inside `limit` is not automatically inside the rule's. Gate on both, and keep
    /// this well under the rule's 20,000 so the two can never disagree.
    static let byteLimit = 16000

    var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Past either ceiling. The counter turns red on this rather than on `limit`
    /// alone, so a long Devanagari message says so before Send goes dead.
    var overLimit: Bool {
        trimmed.count > Self.limit || trimmed.utf8.count > Self.byteLimit
    }

    var canSend: Bool { !trimmed.isEmpty && !overLimit && !sending }

    /// Called as the sheet opens, so a second visit isn't greeted by the last
    /// visit's thank-you or its error. `text` is deliberately untouched — an
    /// unsent draft survives a dismissal.
    func reset() {
        sent = false
        error = nil
    }

    // MARK: - Send

    /// Files the draft as one document in `complaints`.
    ///
    /// ponytail: a POST, not FirebaseFirestore — the same trade publishJoinDate
    /// makes and for the same reason. Unlike that one there is no `documentId=`:
    /// a person files more than one complaint, so Firestore assigns the id.
    func send(as auth: AuthViewModel) async {
        guard canSend else { return }

        // The DEBUG bypass hands out a demo identity with no Firebase account
        // behind it — no uid to file under, no token to sign with. In release
        // there is no signed-out state at all (RootView gates the whole shell),
        // so this guard is reachable only under that bypass.
        guard let user = auth.user else {
            error = "Sign in with your account to send a message."
            return
        }
        // Separate, because neither of these is a sign-in problem: a nil
        // FirebaseApp is a SwiftUI preview (restore() documents the same case),
        // and a nil URL would be a typo in the line above.
        guard let project = FirebaseApp.app()?.options.projectID,
              let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(project)"
                            + "/databases/(default)/documents/complaints")
        else {
            error = "Couldn't reach the server. Email it to \(Self.address) instead."
            return
        }

        sending = true
        error = nil
        defer { sending = false }

        // The name you set on your profile, else the account's — the same
        // precedence the sidebar chip and the Profile header use.
        let chosen = UserDefaults.standard.string(forKey: "profileName") ?? ""
        let username = chosen.isEmpty ? (auth.displayName ?? "") : chosen

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "fields": [
                "userID":   ["stringValue": user.uid],
                "username": ["stringValue": username],
                "email":    ["stringValue": user.email ?? ""],
                "message":  ["stringValue": trimmed],
                // Client clock. createTime is server-set but isn't orderable in a
                // query, and sorting the inbox by date is the point of the field.
                "sentAt":   ["timestampValue": ISO8601DateFormatter().string(from: .now)],
            ]
        ])

        do {
            // The Firebase ID token, not the Google one: the rule matches on
            // request.auth.uid, which only a Firebase token carries.
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                error = "Couldn't send that. Try again, or email it to \(Self.address)."
                return
            }
            // Cleared only on 200. Every other path leaves the draft alone —
            // this is the one place publishJoinDate's silent-retry policy would
            // be wrong to copy, because these are the user's own words.
            text = ""
            sent = true
        } catch {
            self.error = "Couldn't send that. Try again, or email it to \(Self.address)."
        }
    }
}
