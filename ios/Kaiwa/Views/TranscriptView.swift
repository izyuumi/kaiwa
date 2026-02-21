import SwiftUI

enum TranscriptLanguage {
    case jp, en
}

struct TranscriptView: View {
    let entries: [ConversationEntry]
    let language: TranscriptLanguage
    let interimText: String
    let interimLanguage: String
    let showJapanese: Bool
    let isListening: Bool

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(entries) { entry in
                            entryView(entry)
                                .id(entry.id)
                        }

                        if !interimText.isEmpty {
                            interimView
                                .id("interim")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onChange(of: entries.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        if !entries.isEmpty {
                            proxy.scrollTo(entries.last?.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: interimText) { _, _ in
                    if !interimText.isEmpty {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("interim", anchor: .bottom)
                        }
                    }
                }
            }

            // Listening indicator
            if isListening && entries.isEmpty && interimText.isEmpty {
                listeningIndicator
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private func entryView(_ entry: ConversationEntry) -> some View {
        let isJapaneseOriginal = entry.detectedLanguage.hasPrefix("ja")
        let original = isJapaneseOriginal ? entry.jp : entry.en
        let translated = isJapaneseOriginal ? entry.en : entry.jp

        return VStack(alignment: .leading, spacing: 2) {
            Text(Self.timeFormatter.string(from: entry.timestamp))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))
            Text("\(original)  \u{2192}  \(translated)")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(entry.isTranslating ? .gray : .white)
                .italic(entry.isTranslating)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var interimView: some View {
        Text("\(interimText)  \u{2192}  ...")
            .font(.system(size: 22, weight: .regular))
            .foregroundColor(.gray)
            .italic()
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var listeningIndicator: some View {
        VStack(spacing: 12) {
            ListeningPulse()
            Text("Listening...")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct ListeningPulse: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 3, height: animating ? CGFloat.random(in: 8...24) : 8)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: animating
                    )
            }
        }
        .frame(height: 24)
        .onAppear { animating = true }
    }
}
