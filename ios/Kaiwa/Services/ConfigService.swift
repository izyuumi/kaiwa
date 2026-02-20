import Foundation

enum ConfigService {
    static var convexURL: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let url = dict["ConvexURL"] as? String,
              !url.isEmpty else {
            fatalError("Config.plist missing or ConvexURL not set.")
        }
        return url
    }
}
