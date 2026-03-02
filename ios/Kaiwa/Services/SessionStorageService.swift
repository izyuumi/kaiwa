import Foundation

actor SessionStorageService {
    private let userDefaults: UserDefaults
    private let historyKey: String
    private let glossaryKey: String
    private let branchesKey: String
    private let maxHistoryEntries: Int

    init(
        userDefaults: UserDefaults = .standard,
        historyKey: String = "kaiwa.history.entries",
        glossaryKey: String = "kaiwa.history.glossary",
        branchesKey: String = "kaiwa.history.branches",
        maxHistoryEntries: Int = 500
    ) {
        self.userDefaults = userDefaults
        self.historyKey = historyKey
        self.glossaryKey = glossaryKey
        self.branchesKey = branchesKey
        self.maxHistoryEntries = maxHistoryEntries
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

    // MARK: – Branches

    func loadBranches() -> [ConversationBranch] {
        decode(forKey: branchesKey, defaultValue: [])
            .sorted { $0.createdAt > $1.createdAt }
    }

    func saveBranches(_ branches: [ConversationBranch]) {
        encode(branches, forKey: branchesKey)
    }

    // MARK: – Helpers

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
