import Foundation

actor SessionStorageService {
    private let userDefaults: UserDefaults
    private let historyKey: String
    private let glossaryKey: String
    private let sessionsKey: String
    private let maxHistoryEntries: Int
    private let maxSessions: Int

    init(
        userDefaults: UserDefaults = .standard,
        historyKey: String = "kaiwa.history.entries",
        glossaryKey: String = "kaiwa.history.glossary",
        sessionsKey: String = "kaiwa.sessions.v1",
        maxHistoryEntries: Int = 500,
        maxSessions: Int = 200
    ) {
        self.userDefaults = userDefaults
        self.historyKey = historyKey
        self.glossaryKey = glossaryKey
        self.sessionsKey = sessionsKey
        self.maxHistoryEntries = maxHistoryEntries
        self.maxSessions = maxSessions
    }

    func loadHistory() -> [ConversationEntry] {
        decode(forKey: historyKey, defaultValue: [])
            .sorted { $0.timestamp > $1.timestamp }
    }

    func saveHistory(_ entries: [ConversationEntry]) {
        let trimmed = Array(entries.prefix(maxHistoryEntries))
        encode(trimmed, forKey: historyKey)
    }

    func loadGlossary() -> [GlossaryItem] {
        decode(forKey: glossaryKey, defaultValue: [])
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func saveGlossary(_ items: [GlossaryItem]) {
        encode(items, forKey: glossaryKey)
    }

    // MARK: - Conversation Sessions

    func loadSessions() -> [ConversationSession] {
        decode(forKey: sessionsKey, defaultValue: [ConversationSession]())
            .sorted { $0.startedAt > $1.startedAt }
    }

    func saveSessions(_ sessions: [ConversationSession]) {
        let trimmed = Array(sessions.prefix(maxSessions))
        encode(trimmed, forKey: sessionsKey)
    }

    private func decode<T: Decodable>(forKey key: String, defaultValue: T) -> T {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return defaultValue
        }
        return decoded
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        userDefaults.set(data, forKey: key)
    }
}
