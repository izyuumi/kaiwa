import SwiftUI
import ClerkKit

@main
struct KaiwaApp: App {
    init() {
        // Debug logger is only active in DEBUG builds.
        // In production (Release), no Clerk log output reaches the console.
        #if DEBUG
        Clerk.configure(
            publishableKey: ConfigService.clerkPublishableKey,
            options: .init(loggerHandler: { entry in print(entry.formattedMessage) })
        )
        #else
        Clerk.configure(
            publishableKey: ConfigService.clerkPublishableKey,
            options: .init(loggerHandler: nil)
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(Clerk.shared)
                .preferredColorScheme(.dark)
        }
    }
}
