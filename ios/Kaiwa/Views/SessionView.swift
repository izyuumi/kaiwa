import SwiftUI

struct SessionView: View {
    @ObservedObject var viewModel: SessionViewModel
    @ObservedObject private var network = NetworkMonitor.shared
    let onBack: () -> Void

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

            // Offline banner
            if !network.isConnected {
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                        Text("No internet connection")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red.opacity(0.85)))
                    .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .task {
            await viewModel.startSession()
        }
        .onAppear {
            // Lock to portrait — the split-screen layout doesn't work well in landscape
            AppDelegate.orientationLock = .portrait
        }
        .onDisappear {
            AppDelegate.orientationLock = .all
            Task { await viewModel.stopSession() }
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
            HStack(spacing: 16) {
                Spacer()
                if isListening {
                    VoiceActivityDot()
                }
                controlButton
                if isListening {
                    // Entry count
                    Text("\(viewModel.entries.count)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 24)
                } else {
                    Spacer().frame(width: 24)
                }
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
}

struct VoiceActivityDot: View {
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 8, height: 8)
            .scaleEffect(pulsing ? 1.5 : 1.0)
            .opacity(pulsing ? 0.5 : 1.0)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true),
                value: pulsing
            )
            .onAppear { pulsing = true }
    }
}
