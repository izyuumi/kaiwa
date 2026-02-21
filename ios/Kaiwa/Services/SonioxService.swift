import Foundation

protocol SonioxServiceDelegate: AnyObject, Sendable {
    func sonioxDidReceiveInterim(text: String, language: String, confidence: Double?)
    func sonioxDidReceiveFinal(text: String, language: String, confidence: Double?)
    func sonioxDidEncounterError(_ error: Error)
    func sonioxDidStartReconnect(attempt: Int, in delay: TimeInterval)
    func sonioxDidReconnect()
    func sonioxDidDisconnect()
}

final class SonioxService: @unchecked Sendable {
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private var shouldReconnect = false
    private var connectionConfig: ConnectionConfig?
    private var pingTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    weak var delegate: SonioxServiceDelegate?

    private static let wsURL = "wss://stt-rt.soniox.com/transcribe-websocket"
    private let maxReconnectAttempts = 5

    func setDelegate(_ delegate: SonioxServiceDelegate) {
        self.delegate = delegate
    }

    func connect(apiKey: String, model: String, languageHints: [String]) async throws {
        let config = ConnectionConfig(apiKey: apiKey, model: model, languageHints: languageHints)
        connectionConfig = config
        shouldReconnect = true
        try await establishConnection(with: config)
    }

    func sendAudio(_ data: Data) {
        guard isConnected, let task = webSocketTask else {
            return
        }
        task.send(.data(data)) { [weak self] error in
            if let error {
                self?.handleTransportFailure(error)
            }
        }
    }

    func disconnect() async {
        shouldReconnect = false
        pingTask?.cancel()
        pingTask = nil
        receiveTask?.cancel()
        receiveTask = nil

        isConnected = false
        if let task = webSocketTask {
            try? await task.send(.data(Data()))
            task.cancel(with: .normalClosure, reason: nil)
        }
        webSocketTask = nil
        connectionConfig = nil
    }

    private func establishConnection(with config: ConnectionConfig) async throws {
        guard let url = URL(string: Self.wsURL) else {
            throw SonioxError.invalidURL
        }

        pingTask?.cancel()
        receiveTask?.cancel()

        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        webSocketTask = task
        task.resume()

        let configData = try JSONSerialization.data(withJSONObject: config.requestBody)
        guard let configString = String(data: configData, encoding: .utf8) else {
            throw SonioxError.invalidServerResponse
        }
        try await task.send(.string(configString))

        let firstMessage = try await task.receive()
        try parseHandshakeMessage(firstMessage)

        isConnected = true
        startPingLoop(for: task)
        startReceiveLoop(for: task)
    }

    private func startPingLoop(for task: URLSessionWebSocketTask) {
        pingTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.shouldReconnect, self.isConnected, self.webSocketTask === task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                guard self.isConnected, self.webSocketTask === task else { continue }
                task.sendPing { error in
                    if let error {
                        self.handleTransportFailure(error)
                    }
                }
            }
        }
    }

    private func startReceiveLoop(for task: URLSessionWebSocketTask) {
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while self.shouldReconnect, self.isConnected, self.webSocketTask === task {
                do {
                    let message = try await task.receive()
                    switch message {
                    case .string(let text):
                        self.parseResponse(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.parseResponse(text)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    self.handleTransportFailure(error)
                    break
                }
            }
        }
    }

    private func handleTransportFailure(_ error: Error) {
        guard shouldReconnect else { return }
        Task { [weak self] in
            await self?.recoverConnection(after: error)
        }
    }

    private func recoverConnection(after error: Error) async {
        guard shouldReconnect else { return }

        isConnected = false
        pingTask?.cancel()
        receiveTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        guard let config = connectionConfig else {
            delegate?.sonioxDidEncounterError(error)
            delegate?.sonioxDidDisconnect()
            return
        }

        if !Self.isRetryable(error) {
            shouldReconnect = false
            delegate?.sonioxDidEncounterError(error)
            delegate?.sonioxDidDisconnect()
            return
        }

        var attempt = 1
        while shouldReconnect, attempt <= maxReconnectAttempts {
            let delay = min(pow(2.0, Double(attempt - 1)) * 0.5, 8)
            delegate?.sonioxDidStartReconnect(attempt: attempt, in: delay)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            do {
                try await establishConnection(with: config)
                delegate?.sonioxDidReconnect()
                return
            } catch {
                attempt += 1
                if !Self.isRetryable(error) {
                    shouldReconnect = false
                    delegate?.sonioxDidEncounterError(error)
                    delegate?.sonioxDidDisconnect()
                    return
                }
            }
        }

        shouldReconnect = false
        delegate?.sonioxDidEncounterError(SonioxError.connectionLost)
        delegate?.sonioxDidDisconnect()
    }

    private func parseHandshakeMessage(_ message: URLSessionWebSocketTask.Message) throws {
        switch message {
        case .string(let text):
            if text.contains("\"error_code\"") {
                throw SonioxError.serverError(text)
            }
            parseResponse(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                if text.contains("\"error_code\"") {
                    throw SonioxError.serverError(text)
                }
                parseResponse(text)
            }
        @unknown default:
            throw SonioxError.invalidServerResponse
        }
    }

    private func parseResponse(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        if text.contains("\"finished\"") {
            return
        }

        if text.contains("\"error_code\"") {
            delegate?.sonioxDidEncounterError(SonioxError.serverError(text))
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [[String: Any]] else {
            return
        }

        var finalText = ""
        var interimText = ""
        var detectedLanguage = "en"
        var finalConfidenceSum = 0.0
        var finalConfidenceCount = 0.0
        var interimConfidenceSum = 0.0
        var interimConfidenceCount = 0.0
        var hasFinalTokens = false

        for token in tokens {
            let tokenText = token["text"] as? String ?? ""
            let isFinal = token["is_final"] as? Bool ?? false
            let confidence = token["confidence"] as? Double

            if let lang = token["language"] as? String, !lang.isEmpty {
                detectedLanguage = lang
            }

            if isFinal {
                finalText += tokenText
                hasFinalTokens = true
                if let confidence {
                    finalConfidenceSum += confidence
                    finalConfidenceCount += 1
                }
            } else {
                interimText += tokenText
                if let confidence {
                    interimConfidenceSum += confidence
                    interimConfidenceCount += 1
                }
            }
        }

        let finalConfidence = finalConfidenceCount > 0 ? finalConfidenceSum / finalConfidenceCount : nil
        let interimConfidence = interimConfidenceCount > 0 ? interimConfidenceSum / interimConfidenceCount : nil

        let trimmedFinal = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        if hasFinalTokens && !trimmedFinal.isEmpty {
            delegate?.sonioxDidReceiveFinal(
                text: trimmedFinal,
                language: detectedLanguage,
                confidence: finalConfidence
            )
        }

        let trimmedInterim = interimText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInterim.isEmpty {
            delegate?.sonioxDidReceiveInterim(
                text: trimmedInterim,
                language: detectedLanguage,
                confidence: interimConfidence
            )
        }
    }

    private static func isRetryable(_ error: Error) -> Bool {
        if let sonioxError = error as? SonioxError {
            switch sonioxError {
            case .serverError(let message):
                let lowered = message.lowercased()
                return !(lowered.contains("unauthorized") || lowered.contains("invalid api key"))
            case .invalidURL, .invalidServerResponse:
                return false
            case .connectionLost:
                return true
            }
        }

        if let urlError = error as? URLError {
            return [
                .timedOut,
                .networkConnectionLost,
                .cannotConnectToHost,
                .cannotFindHost,
                .notConnectedToInternet,
                .dnsLookupFailed
            ].contains(urlError.code)
        }

        return true
    }
}

private struct ConnectionConfig {
    let apiKey: String
    let model: String
    let languageHints: [String]

    var requestBody: [String: Any] {
        [
            "api_key": apiKey,
            "model": model,
            "audio_format": "pcm_s16le",
            "sample_rate": 16000,
            "num_channels": 1,
            "language_hints": languageHints,
            "enable_endpoint_detection": true,
            "enable_language_identification": true
        ]
    }
}

enum SonioxError: Error, LocalizedError {
    case invalidURL
    case serverError(String)
    case invalidServerResponse
    case connectionLost

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Soniox WebSocket URL"
        case .serverError(let msg):
            return "Soniox error: \(msg)"
        case .invalidServerResponse:
            return "Invalid response from Soniox"
        case .connectionLost:
            return "Connection lost after reconnect attempts"
        }
    }
}
