import Foundation

actor ConvexService {
    private let baseURL: String

    init() {
        self.baseURL = ConfigService.convexURL
    }

    func getSessionAuth() async throws -> SessionAuthResponse {
        let url = URL(string: "\(baseURL)/api/action")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "path": "session:getSessionAuth",
            "args": "{}",
            "format": "json"
        ])

        // Custom encode to get args as object not string
        let body: [String: Any] = [
            "path": "session:getSessionAuth",
            "args": [:] as [String: Any],
            "format": "json"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw ConvexError.requestFailed("Session auth failed: \(bodyStr)")
        }

        let convexResponse = try JSONDecoder().decode(ConvexActionResponse<SessionAuthResponse>.self, from: data)
        return convexResponse.value
    }

    func translate(text: String, detectedLanguage: String) async throws -> TranslationResult {
        let url = URL(string: "\(baseURL)/api/action")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "path": "translate:translate",
            "args": [
                "text": text,
                "detectedLanguage": detectedLanguage
            ],
            "format": "json"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw ConvexError.requestFailed("Translation failed: \(bodyStr)")
        }

        let convexResponse = try JSONDecoder().decode(ConvexActionResponse<TranslationResult>.self, from: data)
        return convexResponse.value
    }
}

struct TranslationResult: Codable {
    let jp: String
    let en: String
}

enum ConvexError: Error, LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let msg): return msg
        }
    }
}
