import SwiftUI

enum SessionState: Equatable {
    case idle
    case connecting
    case listening
    case reconnecting(attempt: Int)
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
    @Published var historyEntries: [ConversationEntry] = []
    @Published var interimText: String = ""
    @Published var interimLanguage: String = ""
    @Published var interimConfidence: Double?
    @Published var languageSide: LanguageSide = .topJP
    @Published var isApproved: Bool = false
    @Published var glossaryItems: [GlossaryItem] = []

    private let convexService = ConvexService()
    private let sonioxService = SonioxService()
    private let audioService = AudioCaptureService()
    private let storageService = SessionStorageService()

    private var cachedAuth: SessionAuthResponse?
    private var isStoppingSession = false
    private var lastTransportErrorMessage: String?

    private var pendingTranslations: [PendingTranslation] = []
    private var translationWorkerTask: Task<Void, Never>?
    private var currentlyTranslatingId: UUID?

    private let maxPendingTranslations = 8
    private let coalesceWindowSeconds = 0.8

    init() {
        audioService.delegate = self
        sonioxService.setDelegate(self)

        Task { @MainActor in
            await loadPersistedState()
        }
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
        if case .reconnecting = state { return }

        isStoppingSession = false
        state = .connecting
        interimText = ""
        interimLanguage = ""
        interimConfidence = nil

        do {
            audioService.stop()
            await sonioxService.disconnect()

            let auth = try await sessionAuth()
            try await sonioxService.connect(
                apiKey: auth.sonioxApiKey,
                model: auth.config.model,
                languageHints: auth.config.languageHints
            )

            try audioService.start()
            state = .listening
            lastTransportErrorMessage = nil
        } catch {
            state = .error(Self.startErrorMessage(from: error))
        }
    }

    func stopSession() async {
        isStoppingSession = true
        audioService.stop()
        await sonioxService.disconnect()
        // Increment session count if we had any conversation entries
        if !entries.isEmpty {
            let key = "kaiwa.totalSessions"
            let current = UserDefaults.standard.integer(forKey: key)
            UserDefaults.standard.set(current + 1, forKey: key)
        }
        state = .idle
        interimText = ""
        interimLanguage = ""
        interimConfidence = nil
        isStoppingSession = false
    }

    func clearHistory() {
        historyEntries = []
        Task {
            await storageService.saveHistory([])
        }
    }

    func removeHistoryEntry(id: UUID) {
        historyEntries.removeAll { $0.id == id }
        Task {
            await storageService.saveHistory(historyEntries)
        }
    }

    func addGlossaryItem(source: String, target: String) {
        let sourceTrimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetTrimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sourceTrimmed.isEmpty, !targetTrimmed.isEmpty else { return }

        if let index = glossaryItems.firstIndex(where: { $0.source.caseInsensitiveCompare(sourceTrimmed) == .orderedSame }) {
            glossaryItems[index] = GlossaryItem(
                id: glossaryItems[index].id,
                source: sourceTrimmed,
                target: targetTrimmed,
                updatedAt: Date()
            )
        } else {
            glossaryItems.insert(
                GlossaryItem(source: sourceTrimmed, target: targetTrimmed),
                at: 0
            )
        }

        Task {
            await storageService.saveGlossary(glossaryItems)
        }
    }

    func removeGlossaryItem(id: UUID) {
        glossaryItems.removeAll { $0.id == id }
        Task {
            await storageService.saveGlossary(glossaryItems)
        }
    }

    private func loadPersistedState() async {
        historyEntries = await storageService.loadHistory()
        glossaryItems = await storageService.loadGlossary()
    }

    private func sessionAuth() async throws -> SessionAuthResponse {
        if let cachedAuth,
           cachedAuth.expiresAt > Date().timeIntervalSince1970 * 1000 {
            return cachedAuth
        }

        let auth = try await convexService.getSessionAuth()
        cachedAuth = auth
        return auth
    }

    private func handleFinalUtterance(text: String, language: String, confidence: Double?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let now = Date()

        if mergeWithLastPendingIfPossible(text: trimmed, language: language, confidence: confidence, now: now) {
            return
        }

        if pendingTranslations.count >= maxPendingTranslations,
           let dropped = pendingTranslations.first {
            pendingTranslations.removeFirst()
            failPendingEntry(id: dropped.entryId, text: dropped.text, language: dropped.language)
        }

        let isJapanese = language.hasPrefix("ja")
        let pendingId = UUID()

        entries.append(ConversationEntry(
            id: pendingId,
            jp: isJapanese ? trimmed : "Translating...",
            en: isJapanese ? "Translating..." : trimmed,
            detectedLanguage: language,
            isTranslating: true,
            confidence: confidence
        ))

        pendingTranslations.append(PendingTranslation(
            entryId: pendingId,
            text: trimmed,
            language: language,
            confidence: confidence,
            createdAt: now
        ))

        interimText = ""
        interimLanguage = ""
        interimConfidence = nil

        startTranslationWorkerIfNeeded()
    }

    private func mergeWithLastPendingIfPossible(
        text: String,
        language: String,
        confidence: Double?,
        now: Date
    ) -> Bool {
        guard var last = pendingTranslations.last,
              last.entryId != currentlyTranslatingId,
              last.language == language,
              now.timeIntervalSince(last.createdAt) <= coalesceWindowSeconds else {
            return false
        }

        last.text += " " + text
        last.createdAt = now
        last.confidence = combinedConfidence(first: last.confidence, second: confidence)
        pendingTranslations[pendingTranslations.count - 1] = last

        let isJapanese = language.hasPrefix("ja")
        updateEntry(
            id: last.entryId,
            jp: isJapanese ? last.text : "Translating...",
            en: isJapanese ? "Translating..." : last.text,
            detectedLanguage: language,
            isTranslating: true,
            confidence: last.confidence
        )

        interimText = ""
        interimLanguage = ""
        interimConfidence = nil
        return true
    }

    private func failPendingEntry(id: UUID, text: String, language: String) {
        let isJapanese = language.hasPrefix("ja")
        updateEntry(
            id: id,
            jp: isJapanese ? text : "[Skipped: translator queue is full]",
            en: isJapanese ? "[Skipped: translator queue is full]" : text,
            detectedLanguage: language,
            isTranslating: false,
            confidence: nil
        )
    }

    private func startTranslationWorkerIfNeeded() {
        guard translationWorkerTask == nil else { return }

        translationWorkerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.translationWorkerTask = nil }

            while !self.pendingTranslations.isEmpty {
                var current = self.pendingTranslations.removeFirst()
                self.currentlyTranslatingId = current.entryId

                do {
                    let result = try await self.convexService.translate(
                        text: current.text,
                        detectedLanguage: current.language,
                        glossary: self.glossaryItems
                    )

                    self.updateEntry(
                        id: current.entryId,
                        jp: result.jp,
                        en: result.en,
                        detectedLanguage: current.language,
                        isTranslating: false,
                        confidence: current.confidence
                    )

                    if let finished = self.entries.first(where: { $0.id == current.entryId }) {
                        self.historyEntries.insert(finished, at: 0)
                        await self.storageService.saveHistory(self.historyEntries)
                    }
                } catch {
                    print("Translation error: \(error)")
                    let isJapanese = current.language.hasPrefix("ja")
                    self.updateEntry(
                        id: current.entryId,
                        jp: isJapanese ? current.text : "[\(error.localizedDescription)]",
                        en: isJapanese ? "[\(error.localizedDescription)]" : current.text,
                        detectedLanguage: current.language,
                        isTranslating: false,
                        confidence: current.confidence
                    )
                }

                self.currentlyTranslatingId = nil
                current.text = ""
            }
        }
    }

    private func updateEntry(
        id: UUID,
        jp: String,
        en: String,
        detectedLanguage: String,
        isTranslating: Bool,
        confidence: Double?
    ) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let existing = entries[index]
        entries[index] = ConversationEntry(
            id: existing.id,
            jp: jp,
            en: en,
            detectedLanguage: detectedLanguage,
            timestamp: existing.timestamp,
            isTranslating: isTranslating,
            confidence: confidence
        )
    }

    private func combinedConfidence(first: Double?, second: Double?) -> Double? {
        switch (first, second) {
        case (.none, .none):
            return nil
        case let (.some(value), .none), let (.none, .some(value)):
            return value
        case let (.some(lhs), .some(rhs)):
            return (lhs + rhs) / 2.0
        }
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

private struct PendingTranslation {
    let entryId: UUID
    var text: String
    let language: String
    var confidence: Double?
    var createdAt: Date
}

extension SessionViewModel: AudioCaptureDelegate {
    nonisolated func audioCaptureDidReceive(buffer: Data) {
        sonioxService.sendAudio(buffer)
    }
}

extension SessionViewModel: SonioxServiceDelegate {
    nonisolated func sonioxDidReceiveInterim(text: String, language: String, confidence: Double?) {
        Task { @MainActor in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            self.interimText = trimmed
            self.interimLanguage = language
            self.interimConfidence = confidence
        }
    }

    nonisolated func sonioxDidReceiveFinal(text: String, language: String, confidence: Double?) {
        Task { @MainActor in
            self.handleFinalUtterance(text: text, language: language, confidence: confidence)
        }
    }

    nonisolated func sonioxDidEncounterError(_ error: Error) {
        Task { @MainActor in
            self.lastTransportErrorMessage = error.localizedDescription
            if case .reconnecting = self.state {
                return
            }
            self.state = .error(error.localizedDescription)
        }
    }

    nonisolated func sonioxDidStartReconnect(attempt: Int, in _: TimeInterval) {
        Task { @MainActor in
            self.state = .reconnecting(attempt: attempt)
        }
    }

    nonisolated func sonioxDidReconnect() {
        Task { @MainActor in
            self.lastTransportErrorMessage = nil
            self.state = .listening
        }
    }

    nonisolated func sonioxDidDisconnect() {
        Task { @MainActor in
            if self.isStoppingSession {
                return
            }

            if case .idle = self.state {
                return
            }

            if case .reconnecting = self.state {
                self.state = .error(self.lastTransportErrorMessage ?? "Connection lost")
                return
            }

            if case .listening = self.state {
                self.state = .error(self.lastTransportErrorMessage ?? "Connection lost")
            }
        }
    }
}
