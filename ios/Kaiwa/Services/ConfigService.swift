import Foundation

enum ConfigService {
    static var convexURL: String {
        "https://kindred-bat-736.eu-west-1.convex.cloud"
    }

    static var clerkPublishableKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["ClerkPublishableKey"] as? String else {
            fatalError("Config.plist missing or ClerkPublishableKey not set.")
        }
        return key
    }
}
