import Foundation

struct ConversationEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let jp: String
    let en: String
    let detectedLanguage: String
    let timestamp: Date
    let isTranslating: Bool
    let confidence: Double?

    init(
        id: UUID = UUID(),
        jp: String,
        en: String,
        detectedLanguage: String,
        timestamp: Date = Date(),
        isTranslating: Bool = false,
        confidence: Double? = nil
    ) {
        self.id = id
        self.jp = jp
        self.en = en
        self.detectedLanguage = detectedLanguage
        self.timestamp = timestamp
        self.isTranslating = isTranslating
        self.confidence = confidence
    }
}
