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
    }

    private func topHalf(height: CGFloat) -> some View {
        let isJP = viewModel.languageSide == .topJP
        return TranscriptView(
            entries: viewModel.entries,
            language: isJP ? .jp : .en,
            interimText: viewModel.interimText,
            interimLanguage: viewModel.interimLanguage,
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
            showJapanese: isJP,
            isListening: isListening
        )
        .frame(height: height)
    }

    private var dividerBar: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 4)
    }

    private var isListening: Bool {
        if case .listening = viewModel.state { return true }
        return false
    }

    private var controlsOverlay: some View {
        VStack {
            Spacer()
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
