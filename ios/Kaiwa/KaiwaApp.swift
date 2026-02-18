import SwiftUI
import ClerkKit

@main
struct KaiwaApp: App {
    init() {
        Clerk.configure(publishableKey: ConfigService.clerkPublishableKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(Clerk.shared)
                .preferredColorScheme(.dark)
        }
    }
}
