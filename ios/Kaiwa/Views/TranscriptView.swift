import SwiftUI

enum TranscriptLanguage {
    case jp, en
}

struct TranscriptView: View {
    let entries: [ConversationEntry]
    let language: TranscriptLanguage
    let interimText: String
    let interimLanguage: String
    let interimConfidence: Double?
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

    private func entryView(_ entry: ConversationEntry) -> some View {
        let isJapaneseOriginal = entry.detectedLanguage.hasPrefix("ja")
        let original = isJapaneseOriginal ? entry.jp : entry.en
        let translated = isJapaneseOriginal ? entry.en : entry.jp

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(languageBadge(for: entry.detectedLanguage))
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())

                if let confidence = entry.confidence {
                    Text("Conf \(Int(confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Text("\(original)  \u{2192}  \(translated)")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(entry.isTranslating ? .gray : .white)
                .italic(entry.isTranslating)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                UIPasteboard.general.string = original
            } label: {
                Label("Copy Original", systemImage: "doc.on.doc")
            }
            Button {
                UIPasteboard.general.string = translated
            } label: {
                Label("Copy Translation", systemImage: "doc.on.doc.fill")
            }
            Button {
                UIPasteboard.general.string = "\(original) → \(translated)"
            } label: {
                Label("Copy Both", systemImage: "doc.on.clipboard")
            }
        }
    }

    private var interimView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(languageBadge(for: interimLanguage))
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

            if let interimConfidence {
                Text("Conf \(Int(interimConfidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Text("\(interimText)  \u{2192}  ...")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.gray)
                .italic()
        }
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

    private func languageBadge(for language: String) -> String {
        if language.hasPrefix("ja") {
            return "JP"
        }
        if language.hasPrefix("en") {
            return "EN"
        }
        return language.isEmpty ? "UNK" : language.uppercased()
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
