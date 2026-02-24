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

    @State private var isScrolledToBottom = true
    @State private var shareText: String?

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

                        // Invisible anchor at the bottom
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onChange(of: entries.count) { _, _ in
                    if isScrolledToBottom, !entries.isEmpty {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: interimText) { _, _ in
                    if isScrolledToBottom, !interimText.isEmpty {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture().onChanged { value in
                        // User scrolling up → pause auto-scroll
                        if value.translation.height > 10 {
                            isScrolledToBottom = false
                        }
                    }
                )

                // "Scroll to bottom" button when paused
                if !isScrolledToBottom {
                    VStack {
                        Spacer()
                        Button {
                            isScrolledToBottom = true
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        } label: {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding(.bottom, 8)
                    }
                    .transition(.opacity)
                }
            }

            // Listening indicator
            if isListening && entries.isEmpty && interimText.isEmpty {
                listeningIndicator
            }
        }
        .sheet(isPresented: Binding(
            get: { shareText != nil },
            set: { if !$0 { shareText = nil } }
        )) {
            if let text = shareText {
                ShareSheet(items: [text])
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

        return VStack(alignment: .leading, spacing: 6) {
            Text(Self.timeFormatter.string(from: entry.timestamp))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))

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
            Divider()
            Button {
                shareText = "\(original) → \(translated)"
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
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
