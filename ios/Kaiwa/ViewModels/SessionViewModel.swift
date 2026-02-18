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

    private let convexService = ConvexService()
    private let sonioxService = SonioxService()
    private let audioService = AudioCaptureService()

    init() {
        audioService.delegate = self
        sonioxService.setDelegate(self)
    }

    func startSession() async {
        state = .connecting

        do {
            // Get auth from Convex
            let auth = try await convexService.getSessionAuth()

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
            state = .error(error.localizedDescription)
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
            do {
                let result = try await self.convexService.translate(text: text, detectedLanguage: language)
                self.entries.append(ConversationEntry(
                    jp: result.jp,
                    en: result.en,
                    detectedLanguage: language
                ))
                self.interimText = ""
            } catch {
                print("Translation error: \(error)")
                let isJapanese = language.hasPrefix("ja")
                self.entries.append(ConversationEntry(
                    jp: isJapanese ? text : "[\(error.localizedDescription)]",
                    en: isJapanese ? "[\(error.localizedDescription)]" : text,
                    detectedLanguage: language
                ))
                self.interimText = ""
            }
        }
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
            self.interimText = text
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
