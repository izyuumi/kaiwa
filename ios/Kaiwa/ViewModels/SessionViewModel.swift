import SwiftUI

enum SessionState {
    case idle
    case connecting
    case listening
    case error(String)
}

enum LanguageSide {
    case topJP   // top=JP (rotated), bottom=EN
    case topEN   // top=EN (rotated), bottom=JP
}

@MainActor
class SessionViewModel: ObservableObject {
    @Published var state: SessionState = .idle
    @Published var entries: [ConversationEntry] = []
    @Published var interimText: String = ""
    @Published var interimLanguage: String = ""
    @Published var languageSide: LanguageSide = .topJP
    @Published var isApproved: Bool = false

    private let convexService = ConvexService()
    private let sonioxService = SonioxService()
    private let audioService = AudioCaptureService()

    /// Cached session auth to avoid redundant key requests
    private var cachedAuth: SessionAuthResponse?

    init() {
        audioService.delegate = self
        sonioxService.setDelegate(self)
    }

    func checkApproval() async {
        do {
            let status = try await convexService.ensureUser()
            isApproved = status.isApproved
        } catch {
            print("Approval check failed: \(error)")
            isApproved = false
        }
    }

    func startSession() async {
        if case .connecting = state { return }
        if case .listening = state { return }

        state = .connecting
        interimText = ""
        interimLanguage = ""

        do {
            // Reset any partial state from previous failed attempts.
            audioService.stop()
            await sonioxService.disconnect()

            // Get auth from Convex (use cache if still valid)
            let auth: SessionAuthResponse
            if let cached = cachedAuth, cached.expiresAt > Double(Date().timeIntervalSince1970 * 1000) {
                auth = cached
            } else {
                auth = try await convexService.getSessionAuth()
                cachedAuth = auth
            }

            // Connect to Soniox
            try await sonioxService.connect(
                apiKey: auth.sonioxApiKey,
                model: auth.config.model,
                languageHints: auth.config.languageHints
            )

            // Start audio capture
            try audioService.start()

            state = .listening
        } catch {
            state = .error(Self.startErrorMessage(from: error))
        }
    }

    func stopSession() async {
        audioService.stop()
        await sonioxService.disconnect()
        state = .idle
        interimText = ""
    }

    private func handleFinalUtterance(text: String, language: String) {
        Task { @MainActor in
            let isJapanese = language.hasPrefix("ja")
            let pendingId = UUID()

            self.entries.append(ConversationEntry(
                id: pendingId,
                jp: isJapanese ? text : "Translating...",
                en: isJapanese ? "Translating..." : text,
                detectedLanguage: language,
                isTranslating: true
            ))
            self.interimText = ""

            do {
                let result = try await self.convexService.translate(text: text, detectedLanguage: language)
                self.updateEntry(
                    id: pendingId,
                    jp: result.jp,
                    en: result.en,
                    detectedLanguage: language
                )
            } catch {
                print("Translation error: \(error)")
                self.updateEntry(
                    id: pendingId,
                    jp: isJapanese ? text : "[\(error.localizedDescription)]",
                    en: isJapanese ? "[\(error.localizedDescription)]" : text,
                    detectedLanguage: language
                )
            }
        }
    }

    private func updateEntry(id: UUID, jp: String, en: String, detectedLanguage: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let existing = entries[index]
        entries[index] = ConversationEntry(
            id: existing.id,
            jp: jp,
            en: en,
            detectedLanguage: detectedLanguage,
            timestamp: existing.timestamp,
            isTranslating: false
        )
    }
}

private extension SessionViewModel {
    static func startErrorMessage(from error: Error) -> String {
        let message = error.localizedDescription
        if message.contains("SONIOX_API_KEY") {
            return "Backend is missing SONIOX_API_KEY."
        }
        return message
    }
}

extension SessionViewModel: AudioCaptureDelegate {
    nonisolated func audioCaptureDidReceive(buffer: Data) {
        sonioxService.sendAudio(buffer)
    }
}

extension SessionViewModel: SonioxServiceDelegate {
    nonisolated func sonioxDidReceiveInterim(text: String, language: String) {
        Task { @MainActor in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            self.interimText = trimmed
            self.interimLanguage = language
        }
    }

    nonisolated func sonioxDidReceiveFinal(text: String, language: String) {
        Task { @MainActor in
            self.handleFinalUtterance(text: text, language: language)
        }
    }

    nonisolated func sonioxDidEncounterError(_ error: Error) {
        Task { @MainActor in
            self.state = .error(error.localizedDescription)
        }
    }

    nonisolated func sonioxDidDisconnect() {
        Task { @MainActor in
            if case .listening = self.state {
                self.state = .error("Connection lost")
            }
        }
    }
}
