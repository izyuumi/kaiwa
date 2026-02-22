import Foundation

struct GlossaryItem: Identifiable, Codable, Hashable {
    let id: UUID
    let source: String
    let target: String
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        source: String,
        target: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.source = source
        self.target = target
        self.updatedAt = updatedAt
    }
}
