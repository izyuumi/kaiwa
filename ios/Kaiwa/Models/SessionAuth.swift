import Foundation

struct SessionAuthConfig: Codable {
    let model: String
    let languageHints: [String]

    enum CodingKeys: String, CodingKey {
        case model
        case languageHints
    }
}

struct SessionAuthResponse: Codable {
    let sonioxApiKey: String
    let config: SessionAuthConfig
}

struct ConvexActionResponse<T: Codable>: Codable {
    let status: String
    let value: T
}
