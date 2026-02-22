import UIKit

/// Controls app-level orientation locking.
/// Set `orientationLock` to restrict rotation during sessions.
class AppDelegate: NSObject, UIApplicationDelegate {
    /// The current orientation lock. Set to `.portrait` during sessions.
    static var orientationLock: UIInterfaceOrientationMask = .all

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        Self.orientationLock
    }
}
