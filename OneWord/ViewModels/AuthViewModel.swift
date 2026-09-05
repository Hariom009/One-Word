//
//  AuthViewModel.swift
//  OneWord
//
//  Optional Google sign-in, the whole feature. Signing in changes nothing about how
//  the app works — the words are bundled and the panes read them offline either way.
//  This is identity only: a name and a face in the Profile pane, and the Firebase
//  session a future sync feature would hang off.
//
//  App target ONLY. Nothing here may move to Shared/ — that folder compiles into the
//  widget (which links no Firebase) and into tools/check_*.sh with bare swiftc.
//
//  macOS is not iOS here: Firebase's own federated flow (Auth.signIn(with:provider:))
//  is inside `#if os(iOS)`, so we fetch the Google ID token ourselves via GoogleSignIn
//  and hand it to Firebase as a credential.
//

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

    var isSignedIn: Bool { user != nil }

    // Read off `user` rather than handed to the view directly, so ProfileView never
    // has to `import FirebaseAuth` to name a type. Keeps the view dumb and the SDK
    // on this side of the seam.
    var displayName: String? { user?.displayName }
    var email: String? { user?.email }
    var photoURL: URL? { user?.photoURL }

    // MARK: - Session

    /// Adopts whatever session Firebase already restored from the keychain.
    ///
    /// The guard is not defensive noise: SwiftUI previews instantiate a view without
    /// the App, so `@NSApplicationDelegateAdaptor` never runs, `FirebaseApp.configure()`
    /// never fires, and `Auth.auth()` calls `fatalError` in exactly that case
    /// (Auth.swift:150). Without it, ProfileView's #Preview crashes on render.
    func restore() {
        guard FirebaseApp.app() != nil else { return }
        // ponytail: a plain read, not addStateDidChangeListener. `currentUser` is a
        // sync hop onto Auth's serial work queue, so it waits behind the keychain
        // load — correct, but it can hitch the main thread on the first call. Swap in
        // the listener if that ever shows up, or if a revoked session needs to
        // clear itself mid-run.
        user = Auth.auth().currentUser
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
}
