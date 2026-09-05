//
//  AuthViewModel.swift
//  OneWord
//
//  Google sign-in, the whole feature. Signing in is how you get into the app at all:
//  RootView shows the sign-in screen and nothing else until `user` is non-nil, so this
//  type is the gate as well as the identity behind the sidebar chip and Profile pane.
//
//  The widget is deliberately outside that gate — it reads the same bundled JSON and
//  has no way to run an OAuth flow, so it keeps showing a word regardless.
//
//  App target ONLY. Nothing here may move to Shared/ — that folder compiles into the
//  widget (which links no Firebase) and into tools/check_*.sh with bare swiftc.
//
//  macOS is not iOS here: Firebase's own federated flow (Auth.signIn(with:provider:))
//  is inside `#if os(iOS)`, so we fetch the Google ID token ourselves via GoogleSignIn
//  and hand it to Firebase as a credential.
//

import Foundation     // UserDefaults — the debug bypass below
import Observation
import AppKit          // NSWindow — the SDK's presenting window, not one of our views
import FirebaseCore    // FirebaseApp — for the preview guard below
import FirebaseAuth
import GoogleSignIn

@Observable
final class AuthViewModel {
    /// The signed-in Firebase user, or nil when signed out. Everything the Profile
    /// pane shows (name, email, photo) hangs off this — no second copy of the
    /// identity from GIDGoogleUser to keep in sync.
    private(set) var user: User?

    /// A sign-in is in flight. The button disables itself rather than letting a
    /// second ASWebAuthenticationSession stack on the first.
    private(set) var busy = false

    /// Last failure, already flattened to something showable. Cancelling is not a
    /// failure and never lands here.
    private(set) var error: String?

    var isSignedIn: Bool {
        #if DEBUG
        user != nil || demo != nil
        #else
        user != nil
        #endif
    }

    #if DEBUG
    /// The demo account behind the debug bypass. A rebuild re-signs the bundle,
    /// which loses the keychain session, so every run would otherwise cost another
    /// Google round trip. Set it from SignInView's "Skip sign-in" button or by
    /// adding `-debugSkipAuth YES` to the scheme's arguments — UserDefaults reads
    /// the argument domain too, so either way it survives the next launch.
    ///
    /// Firebase's `User` is `final` and only ever handed out by the SDK, so this
    /// is a second identity the accessors below fall back to rather than a fake
    /// one stuffed into `user`. Everything downstream reads those accessors, so
    /// the header, the sidebar chip, the details rows and Sign out all behave.
    private(set) var demo: DemoUser?

    /// Signed out in a debug run means signed out — the bypass is cleared, not
    /// re-read on the next launch.
    static let bypassKey = "debugSkipAuth"

    func skipSignIn() {
        UserDefaults.standard.set(true, forKey: Self.bypassKey)
        demo = DemoUser()
    }

    struct DemoUser {
        let name = "Demo Tester"
        let email = "demo@oneword.app"
        /// Fixed, so "member since" doesn't read as today on every launch.
        let joined = Date(timeIntervalSince1970: 1_700_000_000)   // Nov 2023
        let photoURL = AuthViewModel.demoPhotoURL()
    }

    /// A file URL for the account photo. `AsyncImage` goes through URLSession,
    /// which serves `file://` — so the bundled illustration stands in for a Google
    /// photo with no network, and the `.account` tile in the picker shows a real
    /// picture instead of the empty-account head.
    private static func demoPhotoURL() -> URL? {
        let url = URL.cachesDirectory.appending(path: "oneword-demo-avatar.png")
        guard !FileManager.default.fileExists(atPath: url.path) else { return url }
        guard let tiff = NSImage(named: "male_profile_icon")?.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]),
              (try? png.write(to: url)) != nil
        else { return nil }   // no photo is a real account state; the head covers it
        return url
    }
    #endif

    /// False until `restore()` has run once. The gate waits on this rather than on
    /// `isSignedIn` alone — otherwise a returning user is briefly "signed out" and
    /// the sign-in screen flashes before the keychain session lands.
    private(set) var restored = false

    // Read off `user` rather than handed to the view directly, so ProfileView never
    // has to `import FirebaseAuth` to name a type. Keeps the view dumb and the SDK
    // on this side of the seam.
    #if DEBUG
    var displayName: String? { user?.displayName ?? demo?.name }
    var email: String? { user?.email ?? demo?.email }
    var photoURL: URL? { user?.photoURL ?? demo?.photoURL }
    #else
    var displayName: String? { user?.displayName }
    var email: String? { user?.email }
    var photoURL: URL? { user?.photoURL }
    #endif
    /// When the account was first created — the Profile pane's "member since".
    /// The stamp this Mac wrote down first (see `recordJoinDate()`), Firebase's own
    /// metadata behind it. Same value: the stamp is copied from the metadata. It
    /// leads because it's a defaults read rather than a hop onto Auth's queue, and
    /// because it's the exact copy the `users` record was written from.
    #if DEBUG
    var joined: Date? { accountJoined ?? demo?.joined }
    #else
    var joined: Date? { accountJoined }
    #endif

    private var accountJoined: Date? {
        guard let user else { return nil }
        return Self.storedJoin(for: user.uid) ?? user.metadata.creationDate
    }

    // MARK: - Session

    /// Adopts whatever session Firebase already restored from the keychain.
    ///
    /// The guard is not defensive noise: SwiftUI previews instantiate a view without
    /// the App, so `@NSApplicationDelegateAdaptor` never runs, `FirebaseApp.configure()`
    /// never fires, and `Auth.auth()` calls `fatalError` in exactly that case
    /// (Auth.swift:150). Without it, ProfileView's #Preview crashes on render.
    func restore() {
        // Set even when Firebase is absent (previews): "we looked" is the fact the
        // gate needs, and a preview that never resolves would hang on a blank window.
        defer { restored = true }
        #if DEBUG
        if UserDefaults.standard.bool(forKey: Self.bypassKey) { demo = DemoUser() }
        #endif
        guard FirebaseApp.app() != nil else { return }
        // ponytail: a plain read, not addStateDidChangeListener. `currentUser` is a
        // sync hop onto Auth's serial work queue, so it waits behind the keychain
        // load — correct, but it can hitch the main thread on the first call. Swap in
        // the listener if that ever shows up, or if a revoked session needs to
        // clear itself mid-run.
        user = Auth.auth().currentUser
        let dbg = "user=\(user == nil ? "nil" : "present")\ntop=\(String(describing: user?.photoURL))\nproviders=\(user?.providerData.map { "\($0.providerID) | \(String(describing: $0.photoURL))" } ?? [])\n"
        try? dbg.write(to: URL.cachesDirectory.appending(path: "photodebug.txt"), atomically: true, encoding: .utf8)
        recordJoinDate()
    }

    // MARK: - Sign in / out

    /// Runs the Google flow, then trades the resulting ID token for a Firebase session.
    /// `window` is only ever the anchor for `ASWebAuthenticationSession`.
    func signIn(presenting window: NSWindow) async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            guard let idToken = result.user.idToken?.tokenString else {
                // Documented nullable, and Firebase cannot build a credential without
                // it — so this is a real failure, not something to paper over.
                error = "Google didn't return an ID token."
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            user = try await Auth.auth().signIn(with: credential).user
            // Right here is the only moment a brand-new account exists for the
            // first time — restore() catches every launch after it.
            recordJoinDate()
        } catch let gid as GIDSignInError where gid.code == .canceled {
            // Closing the browser window is a decision, not an error worth a banner.
            return
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Both halves, deliberately. Dropping only the Firebase session leaves
    /// GoogleSignIn's own keychain entry behind.
    func signOut() {
        #if DEBUG
        // Always dropped, even when a real session is also live — otherwise the
        // bypass outlives the sign-out and the gate never closes.
        UserDefaults.standard.removeObject(forKey: Self.bypassKey)
        demo = nil
        // With nothing real to sign out of, stop here: Auth.signOut() with no
        // current user throws, and the message lands under the sign-in button.
        if user == nil {
            error = nil
            return
        }
        #endif
        guard FirebaseApp.app() != nil else { return }
        GIDSignIn.sharedInstance.signOut()
        do {
            try Auth.auth().signOut()
            user = nil
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Join date

    private static func joinKey(_ uid: String) -> String { "profileJoined.\(uid)" }
    private static func syncKey(_ uid: String) -> String { "profileJoinedSynced.\(uid)" }

    /// The day this account was made, read back off this Mac. Keyed by uid so
    /// signing in as someone else shows their date and not the last person's.
    private static func storedJoin(for uid: String) -> Date? {
        let stamp = UserDefaults.standard.double(forKey: joinKey(uid))
        return stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
    }

    /// Writes the account's creation date down in both places the first time we see
    /// it: local defaults, and `users/{uid}` in Firestore. Called on every sign-in
    /// and every restore, but both writes are first-one-wins, so from the second
    /// launch on it costs a defaults read and stops.
    private func recordJoinDate() {
        guard let user, let joined = user.metadata.creationDate else { return }
        let defaults = UserDefaults.standard
        if defaults.double(forKey: Self.joinKey(user.uid)) == 0 {
            defaults.set(joined.timeIntervalSince1970, forKey: Self.joinKey(user.uid))
        }
        // Still unmarked means the last push never landed — offline first launch,
        // or Firestore unreachable. Trying again next launch is the whole retry
        // policy; there is nothing here worth a queue.
        guard !defaults.bool(forKey: Self.syncKey(user.uid)) else { return }
        Task { await publishJoinDate(joined, for: user) }
    }

    /// Creates `users/{uid}` with the join date, over Firestore's REST API.
    ///
    /// ponytail: a POST, not FirebaseFirestore. The SDK drags gRPC, leveldb and
    /// abseil into a build that links two small Firebase products — to write one
    /// field, once, per account. Add it the day something needs offline queueing or
    /// live listeners; that is what it actually buys.
    ///
    /// `documentId=` makes this create-only, not upsert: an account that already has
    /// a record comes back 409 and its stored date is left alone. First write wins,
    /// enforced by the server, so a second Mac can't rewrite the day you joined and
    /// there's no read-before-write to race.
    ///
    /// Failure is deliberately silent. Signing in worked; a bookkeeping write that
    /// didn't is not something to put under the sign-in button, and the guard in
    /// `recordJoinDate()` already retries it.
    private func publishJoinDate(_ joined: Date, for user: User) async {
        guard let project = FirebaseApp.app()?.options.projectID,
              let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(project)"
                            + "/databases/(default)/documents/users?documentId=\(user.uid)")
        else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "fields": ["joined": ["timestampValue": ISO8601DateFormatter().string(from: joined)]]
        ])

        do {
            // The Firebase ID token, not the Google one: rules match on
            // `request.auth.uid`, which only a Firebase token carries.
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            // 409 is ALREADY_EXISTS — the record is there, which is the outcome we
            // wanted, so it counts as done and stops the retry.
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            if code == 200 || code == 409 {
                UserDefaults.standard.set(true, forKey: Self.syncKey(user.uid))
            }
        } catch {
            // Left unmarked on purpose: the next launch tries again.
        }
    }
}
