import Foundation
import ClerkKit

actor ConvexService {
    private let baseURL: String

    init() {
        self.baseURL = ConfigService.convexURL
    }

    private func getAuthToken() async throws -> String {
        let session = await MainActor.run { Clerk.shared.session }
        guard let session else {
            throw ConvexError.requestFailed("Not authenticated — no active Clerk session")
        }
        guard let token = try await session.getToken(.init(template: "convex")) else {
            throw ConvexError.requestFailed("Failed to get Clerk JWT for Convex")
        }
        return token
    }

    func getSessionAuth() async throws -> SessionAuthResponse {
        let token = try await getAuthToken()

        let url = URL(string: "\(baseURL)/api/action")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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

    func ensureUser() async throws -> UserStatus {
        let token = try await getAuthToken()

        let url = URL(string: "\(baseURL)/api/mutation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "path": "users:ensureUser",
            "args": [:] as [String: Any],
            "format": "json"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw ConvexError.requestFailed("ensureUser failed: \(bodyStr)")
        }

        let convexResponse = try JSONDecoder().decode(ConvexQueryResponse<UserStatus>.self, from: data)
        return convexResponse.value
    }

    func translate(text: String, detectedLanguage: String) async throws -> TranslationResult {
        let token = try await getAuthToken()

        let url = URL(string: "\(baseURL)/api/action")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
