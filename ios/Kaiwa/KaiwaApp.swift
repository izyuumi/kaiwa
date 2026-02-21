import SwiftUI
import ClerkKit

@main
struct KaiwaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Clerk.configure(
            publishableKey: ConfigService.clerkPublishableKey,
            options: .init(
                loggerHandler: { entry in
                    print(entry.formattedMessage)
                }
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(Clerk.shared)
                .preferredColorScheme(.dark)
        }
    }
}
