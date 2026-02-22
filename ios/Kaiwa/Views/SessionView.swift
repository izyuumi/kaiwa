import SwiftUI

struct SessionView: View {
    @ObservedObject var viewModel: SessionViewModel
    let onBack: () -> Void
    @State private var sessionStart: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let dividerHeight: CGFloat = 4
                let halfHeight = (geo.size.height - dividerHeight) / 2

                VStack(spacing: 0) {
                    // Top half is for the opposite user, so rotate 180°.
                    topHalf(height: halfHeight)
                        .rotationEffect(.degrees(180))

                    // Divider
                    dividerBar

                    // Bottom half
                    bottomHalf(height: halfHeight)
                }
            }

            // Controls overlay
            controlsOverlay
        }
        .task {
            await viewModel.startSession()
        }
        .onDisappear {
            Task { await viewModel.stopSession() }
            timer?.invalidate()
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .listening = newState {
                if sessionStart == nil {
                    sessionStart = Date()
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        if let start = sessionStart {
                            elapsedTime = Date().timeIntervalSince(start)
                        }
                    }
                }
            } else if case .idle = newState {
                timer?.invalidate()
                timer = nil
                sessionStart = nil
                elapsedTime = 0
            }
        }
    }

    private func topHalf(height: CGFloat) -> some View {
        let isJP = viewModel.languageSide == .topJP
        return TranscriptView(
            entries: viewModel.entries,
            language: isJP ? .jp : .en,
            interimText: viewModel.interimText,
            interimLanguage: viewModel.interimLanguage,
            interimConfidence: viewModel.interimConfidence,
            showJapanese: isJP,
            isListening: isListening
        )
        .frame(height: height)
    }

    private func bottomHalf(height: CGFloat) -> some View {
        let isJP = viewModel.languageSide != .topJP
        return TranscriptView(
            entries: viewModel.entries,
            language: isJP ? .jp : .en,
            interimText: viewModel.interimText,
            interimLanguage: viewModel.interimLanguage,
            interimConfidence: viewModel.interimConfidence,
            showJapanese: isJP,
            isListening: isListening
        )
        .frame(height: height)
    }

    private var dividerBar: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.languageSide = viewModel.languageSide == .topJP ? .topEN : .topJP
            }
        } label: {
            HStack {
                Spacer()
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            }
            .frame(height: 28)
            .background(Color.gray.opacity(0.15))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Swap language sides")
    }

    private var isListening: Bool {
        if case .listening = viewModel.state { return true }
        if case .reconnecting = viewModel.state { return true }
        return false
    }

    private var controlsOverlay: some View {
        VStack {
            Spacer()
            // Duration display
            if sessionStart != nil {
                Text(formatDuration(elapsedTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 4)
            }
            HStack {
                Spacer()
                controlButton
                Spacer()
            }
            if case .error(let message) = viewModel.state {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }
            if case .reconnecting(let attempt) = viewModel.state {
                Text("Reconnecting... (attempt \(attempt))")
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var controlButton: some View {
        switch viewModel.state {
        case .idle, .error:
            Button {
                Task { await viewModel.startSession() }
            } label: {
                controlIcon(systemName: "play.fill", color: .green)
            }
        case .connecting:
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.white.opacity(0.1)))
        case .reconnecting:
            Button {
                Task { await viewModel.stopSession() }
            } label: {
                controlIcon(systemName: "stop.fill", color: .orange)
            }
        case .listening:
            Button {
                Task { await viewModel.stopSession() }
            } label: {
                controlIcon(systemName: "stop.fill", color: .red)
            }
        }
    }

    private func controlIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.title2)
            .foregroundColor(color)
            .frame(width: 56, height: 56)
            .background(Circle().fill(Color.white.opacity(0.1)).blur(radius: 0.5))
            .overlay(Circle().stroke(color.opacity(0.5), lineWidth: 1))
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
