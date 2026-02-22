import XCTest
@testable import Kaiwa

final class SessionStorageServiceTests: XCTestCase {
    func testHistoryRoundTrip() async {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let storage = SessionStorageService(
            userDefaults: defaults,
            historyKey: "history",
            glossaryKey: "glossary"
        )

        let entry = ConversationEntry(
            jp: "おはようございます",
            en: "Good morning",
            detectedLanguage: "ja",
            isTranslating: false,
            confidence: 0.9
        )

        await storage.saveHistory([entry])
        let loaded = await storage.loadHistory()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.jp, "おはようございます")
        XCTAssertEqual(loaded.first?.en, "Good morning")
        XCTAssertEqual(loaded.first?.confidence, 0.9)
    }

    func testGlossaryRoundTrip() async {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let storage = SessionStorageService(
            userDefaults: defaults,
            historyKey: "history",
            glossaryKey: "glossary"
        )

        let term = GlossaryItem(source: "NDA", target: "秘密保持契約")
        await storage.saveGlossary([term])
        let loaded = await storage.loadGlossary()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.source, "NDA")
        XCTAssertEqual(loaded.first?.target, "秘密保持契約")
    }
}
