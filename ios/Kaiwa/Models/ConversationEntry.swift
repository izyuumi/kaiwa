import Foundation

struct ConversationEntry: Identifiable {
    let id = UUID()
    let jp: String
    let en: String
    let detectedLanguage: String
    let timestamp: Date

    init(jp: String, en: String, detectedLanguage: String, timestamp: Date = Date()) {
        self.jp = jp
        self.en = en
        self.detectedLanguage = detectedLanguage
        self.timestamp = timestamp
    }
}
