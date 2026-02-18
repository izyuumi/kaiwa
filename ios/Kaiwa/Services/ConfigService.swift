import Foundation

enum ConfigService {
    static var convexURL: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let url = dict["ConvexURL"] as? String else {
            fatalError("Config.plist missing or ConvexURL not set. Copy Config.plist.example to Config.plist and fill in values.")
        }
        return url
    }
}
