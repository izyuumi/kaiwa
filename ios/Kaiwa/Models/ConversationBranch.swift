import Foundation

/// A recorded conversation session that can branch from another session.
struct ConversationBranch: Identifiable, Codable, Hashable {
    let id: UUID
    /// ID of the parent branch this session diverged from. `nil` = root session.
    let parentBranchId: UUID?
    /// The entry in the parent branch at which this branch diverges.
    let branchPointEntryId: UUID?
    /// Human-readable label (auto-generated from date/time when empty).
    let name: String
    let createdAt: Date
    /// All entries in this branch (includes entries inherited from the parent for context).
    let entries: [ConversationEntry]

    init(
        id: UUID = UUID(),
        parentBranchId: UUID? = nil,
        branchPointEntryId: UUID? = nil,
        name: String = "",
        createdAt: Date = Date(),
        entries: [ConversationEntry] = []
    ) {
        self.id = id
        self.parentBranchId = parentBranchId
        self.branchPointEntryId = branchPointEntryId
        self.createdAt = createdAt
        self.entries = entries
        self.name = name.isEmpty ? Self.defaultName(from: createdAt) : name
    }

    private static func defaultName(from date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}

/// Tree node wrapping a branch with resolved children for display.
struct BranchNode: Identifiable {
    let branch: ConversationBranch
    var children: [BranchNode]
    var id: UUID { branch.id }
}

extension [ConversationBranch] {
    /// Build a forest of `BranchNode` trees from a flat array of branches.
    func buildTree() -> [BranchNode] {
        func childNodes(of parentId: UUID?) -> [BranchNode] {
            self
                .filter { $0.parentBranchId == parentId }
                .sorted { $0.createdAt < $1.createdAt }
                .map { branch in
                    BranchNode(branch: branch, children: childNodes(of: branch.id))
                }
        }
        return childNodes(of: nil)
    }
}
