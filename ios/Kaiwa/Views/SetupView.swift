import SwiftUI

struct SetupView: View {
    @ObservedObject var viewModel: SessionViewModel
    let isApproved: Bool
    let onStart: () -> Void
    @AppStorage("kaiwa.totalSessions") private var totalSessions: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Text("会話")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundColor(.white)

                Text("Kaiwa")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.gray)

                VStack(spacing: 16) {
                    Text("Choose layout")
                        .font(.headline)
                        .foregroundColor(.gray)

                    HStack(spacing: 24) {
                        layoutButton(
                            topLabel: "🇯🇵 日本語",
                            bottomLabel: "🇬🇧 English",
                            side: .topJP
                        )

                        layoutButton(
                            topLabel: "🇬🇧 English",
                            bottomLabel: "🇯🇵 日本語",
                            side: .topEN
                        )
                    }
                }

                Button(action: {
                    onStart()
                }) {
                    Text("Start Session")
                        .font(.title3.weight(.medium))
                        .foregroundColor(isApproved ? .black : .gray)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(isApproved ? Color.white : Color.white.opacity(0.3))
                        .clipShape(Capsule())
                }
                .disabled(!isApproved)

                if !isApproved {
                    Text("Your account is pending approval.\nPlease contact the administrator.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                if totalSessions > 0 {
                    Text("\(totalSessions) conversation\(totalSessions == 1 ? "" : "s") completed")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }

                Spacer()

                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
    }

    private func layoutButton(topLabel: String, bottomLabel: String, side: LanguageSide) -> some View {
        let isSelected = viewModel.languageSide == side

        return Button {
            viewModel.languageSide = side
        } label: {
            VStack(spacing: 0) {
                Text(topLabel)
                    .rotationEffect(.degrees(180))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))

                Divider().background(Color.gray)

                Text(bottomLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(width: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}
