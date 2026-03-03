import Foundation

/// A recorded conversation session that groups translated entries.
/// Sessions can form a tree: a branch session has a `parentSessionId`
/// pointing to the session it was forked from.
struct ConversationSession: Identifiable, Codable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let entries: [ConversationEntry]
    /// `nil` for root sessions; set to the parent session's id for branches.
    let parentSessionId: UUID?
    /// Optional user-supplied label (e.g. "Dinner conversation").
    var label: String?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date = Date(),
        entries: [ConversationEntry],
        parentSessionId: UUID? = nil,
        label: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.entries = entries
        self.parentSessionId = parentSessionId
        self.label = label
    }
}

extension ConversationSession {
    /// Direct children (branches) of this session, oldest first.
    func children(in sessions: [ConversationSession]) -> [ConversationSession] {
        sessions
            .filter { $0.parentSessionId == self.id }
            .sorted { $0.startedAt < $1.startedAt }
    }

    /// Top-level sessions (no parent), newest first.
    static func rootSessions(from sessions: [ConversationSession]) -> [ConversationSession] {
        sessions
            .filter { $0.parentSessionId == nil }
            .sorted { $0.startedAt > $1.startedAt }
    }

    /// A short preview of the session content.
    var preview: String {
        guard let first = entries.first else { return "Empty session" }
        let text = first.detectedLanguage.hasPrefix("ja") ? first.jp : first.en
        return text.isEmpty ? "…" : text
    }

    /// How long the session lasted.
    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}
