import Foundation
import ClerkKit

actor ConvexService {
    private let baseURL: String
    private let session: URLSession

    init() {
        self.baseURL = ConfigService.convexURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 20
        self.session = URLSession(configuration: config)
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
        let body: [String: Any] = [
            "path": "session:getSessionAuth",
            "args": [:] as [String: Any],
            "format": "json"
        ]
        return try await post(
            endpoint: .action,
            path: "session:getSessionAuth",
            body: body
        )
    }

    func ensureUser() async throws -> UserStatus {
        let body: [String: Any] = [
            "path": "users:ensureUser",
            "args": [:] as [String: Any],
            "format": "json"
        ]
        return try await post(
            endpoint: .mutation,
            path: "users:ensureUser",
            body: body
        )
    }

    func translate(
        text: String,
        detectedLanguage: String,
        glossary: [GlossaryItem]
    ) async throws -> TranslationResult {
        let glossaryPayload = glossary.map {
            ["source": $0.source, "target": $0.target]
        }
        let body: [String: Any] = [
            "path": "translate:translate",
            "args": [
                "text": text,
                "detectedLanguage": detectedLanguage,
                "glossary": glossaryPayload
            ],
            "format": "json"
        ]
        return try await post(
            endpoint: .action,
            path: "translate:translate",
            body: body
        )
    }

    private func decodeConvexSuccessResponse<T: Decodable>(_ data: Data, endpoint: String) throws -> T {
        let decoder = JSONDecoder()
        let bodyString = String(data: data, encoding: .utf8) ?? "unknown"

        do {
            let envelope = try decoder.decode(ConvexResponseEnvelope<T>.self, from: data)

            if envelope.status != "success" {
                let errorText = envelope.errorMessage
                    ?? envelope.errorData?.message
                    ?? bodyString
                throw ConvexError.requestFailed("\(endpoint) failed: \(errorText)")
            }

            guard let value = envelope.value else {
                throw ConvexError.requestFailed("\(endpoint) failed: missing value in successful response")
            }

            return value
        } catch let decodingError as DecodingError {
            throw ConvexError.requestFailed("\(endpoint) response decode failed: \(Self.describe(decodingError)); body=\(bodyString)")
        }
    }

    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case .dataCorrupted(let context):
            return "data corrupted (\(context.debugDescription))"
        case .keyNotFound(let key, let context):
            return "missing key '\(key.stringValue)' (\(context.debugDescription))"
        case .typeMismatch(let type, let context):
            return "type mismatch for \(type) (\(context.debugDescription))"
        case .valueNotFound(let type, let context):
            return "missing value for \(type) (\(context.debugDescription))"
        @unknown default:
            return "unknown decoding error"
        }
    }

    private func post<T: Decodable>(
        endpoint: ConvexEndpoint,
        path: String,
        body: [String: Any],
        maxAttempts: Int = 3
    ) async throws -> T {
        let token = try await getAuthToken()
        var attempt = 0
        var lastError: Error?

        while attempt < maxAttempts {
            attempt += 1
            do {
                let data = try await executeRequest(
                    endpoint: endpoint,
                    token: token,
                    body: body,
                    logicalPath: path
                )
                return try decodeConvexSuccessResponse(data, endpoint: path)
            } catch {
                lastError = error
                if attempt >= maxAttempts || !Self.shouldRetry(error) {
                    throw error
                }
                let delayNs = UInt64(200_000_000 * attempt)
                try? await Task.sleep(nanoseconds: delayNs)
            }
        }

        throw lastError ?? ConvexError.requestFailed("\(path) failed")
    }

    private func executeRequest(
        endpoint: ConvexEndpoint,
        token: String,
        body: [String: Any],
        logicalPath: String
    ) async throws -> Data {
        let url = URL(string: "\(baseURL)/api/\(endpoint.rawValue)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConvexError.requestFailed("\(logicalPath) failed: invalid response")
        }
        guard httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw ConvexError.requestFailed("\(logicalPath) failed: \(bodyStr)")
        }
        return data
    }

    private static func shouldRetry(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            return [
                .timedOut,
                .networkConnectionLost,
                .cannotConnectToHost,
                .cannotFindHost,
                .notConnectedToInternet
            ].contains(urlError.code)
        }
        return false
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

private struct ConvexResponseEnvelope<T: Decodable>: Decodable {
    let status: String
    let value: T?
    let errorMessage: String?
    let errorData: ConvexErrorData?
}

private struct ConvexErrorData: Decodable {
    let message: String?
}

private enum ConvexEndpoint: String {
    case action
    case mutation
}
