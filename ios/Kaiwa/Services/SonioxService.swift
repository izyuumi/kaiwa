import Foundation

protocol SonioxServiceDelegate: AnyObject, Sendable {
    func sonioxDidReceiveInterim(text: String, language: String)
    func sonioxDidReceiveFinal(text: String, language: String)
    func sonioxDidEncounterError(_ error: Error)
    func sonioxDidDisconnect()
}

final class SonioxService: @unchecked Sendable {
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    weak var delegate: SonioxServiceDelegate?

    private static let wsURL = "wss://stt-rt.soniox.com/transcribe-websocket"

    func setDelegate(_ delegate: SonioxServiceDelegate) {
        self.delegate = delegate
    }

    func connect(apiKey: String, model: String, languageHints: [String]) async throws {
        guard let url = URL(string: Self.wsURL) else {
            throw SonioxError.invalidURL
        }

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        // Send config — if this succeeds the WebSocket handshake completed
        let config: [String: Any] = [
            "api_key": apiKey,
            "model": model,
            "audio_format": "pcm_s16le",
            "sample_rate": 16000,
            "num_channels": 1,
            "language_hints": languageHints,
            "enable_endpoint_detection": true,
            "enable_language_identification": true
        ]
        let configData = try JSONSerialization.data(withJSONObject: config)
        let configString = String(data: configData, encoding: .utf8)!
        try await webSocketTask?.send(.string(configString))

        // Wait for the first server response with a timeout
        guard let task = webSocketTask else {
            throw SonioxError.serverError("WebSocket task deallocated")
        }
        let firstMessage: URLSessionWebSocketTask.Message = try await withThrowingTaskGroup(of: URLSessionWebSocketTask.Message.self) { group in
            group.addTask {
                try await task.receive()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                throw SonioxError.connectionTimeout
            }
            guard let result = try await group.next() else {
                throw SonioxError.connectionTimeout
            }
            group.cancelAll()
            return result
        }
        switch firstMessage {
        case .string(let text):
            if text.contains("\"error_code\"") {
                throw SonioxError.serverError(text)
            }
            // Valid first response — connection confirmed
            parseResponse(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                if text.contains("\"error_code\"") {
                    throw SonioxError.serverError(text)
                }
                parseResponse(text)
            }
        @unknown default:
            break
        }

        isConnected = true

        // Start receiving loop now that connection is confirmed
        Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    func sendAudio(_ data: Data) {
        guard isConnected, let task = webSocketTask else {
            // Not connected yet or already disconnected — drop audio silently
            return
        }
        task.send(.data(data)) { [weak self] error in
            if let error = error {
                self?.isConnected = false
                self?.delegate?.sonioxDidEncounterError(error)
            }
        }
    }

    func disconnect() async {
        isConnected = false
        if let task = webSocketTask {
            try? await task.send(.data(Data()))
        }
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    private func receiveLoop() async {
        guard let task = webSocketTask else { return }
        while isConnected {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    parseResponse(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        parseResponse(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                if isConnected {
                    delegate?.sonioxDidEncounterError(error)
                    delegate?.sonioxDidDisconnect()
                }
                break
            }
        }
    }

    private func parseResponse(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        // Check for finished
        if text.contains("\"finished\"") { return }

        // Check for error
        if text.contains("\"error_code\"") {
            delegate?.sonioxDidEncounterError(SonioxError.serverError(text))
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [[String: Any]] else {
            return
        }

        // Build text from tokens, detect language and finality
        var finalText = ""
        var interimText = ""
        var detectedLanguage = "en"
        var hasFinalTokens = false

        for token in tokens {
            let tokenText = token["text"] as? String ?? ""
            let isFinal = token["is_final"] as? Bool ?? false
            if let lang = token["language"] as? String, !lang.isEmpty {
                detectedLanguage = lang
            }
            if isFinal {
                finalText += tokenText
                hasFinalTokens = true
            } else {
                interimText += tokenText
            }
        }

        if hasFinalTokens && !finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            delegate?.sonioxDidReceiveFinal(
                text: finalText.trimmingCharacters(in: .whitespacesAndNewlines),
                language: detectedLanguage
            )
        }

        if !interimText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            delegate?.sonioxDidReceiveInterim(
                text: interimText.trimmingCharacters(in: .whitespacesAndNewlines),
                language: detectedLanguage
            )
        }
    }
}

enum SonioxError: Error, LocalizedError {
    case invalidURL
    case connectionTimeout
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Soniox WebSocket URL"
        case .connectionTimeout: return "Connection timed out. Check your internet and try again."
        case .serverError(let msg): return "Soniox error: \(msg)"
        }
    }
}
