import XCTest
@testable import Kaiwa

final class ConversationEntryTests: XCTestCase {
    func testConversationEntryCodableRoundTrip() throws {
        let original = ConversationEntry(
            id: UUID(),
            jp: "会議は3時からです。",
            en: "The meeting starts at 3 PM.",
            detectedLanguage: "ja",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            isTranslating: false,
            confidence: 0.82
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ConversationEntry.self, from: data)

        XCTAssertEqual(decoded, original)
    }
}
