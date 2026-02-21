import SwiftUI
import AuthenticationServices
import ClerkKit
import ClerkKitUI

struct AuthSheet: View {
    @State private var showingDiagnostics = false
    @State private var lastAppleSignInError: AppleSignInErrorSnapshot?

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign in to Kaiwa")
                .font(.headline)

            HStack {
                Spacer()
                Button("Open diagnostics") {
                    showingDiagnostics = true
                }
                .font(.footnote)
            }

            AuthView(isDismissable: false)
        }
        .padding()
        .sheet(isPresented: $showingDiagnostics) {
            AuthDiagnosticsView(lastAppleSignInError: lastAppleSignInError)
        }
        .preferredColorScheme(.dark)
        .tint(.green)
    }
}

private struct AppleSignInErrorSnapshot: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let domain: String
    let code: Int
    let codeLabel: String?
    let message: String
    let failureReason: String?
    let recoverySuggestion: String?

    var alertMessage: String {
        var lines: [String] = []
        if let codeLabel, !codeLabel.isEmpty {
            lines.append("[\(domain):\(code)] \(codeLabel)")
        } else {
            lines.append("[\(domain):\(code)]")
        }
        lines.append(message)
        if let failureReason, !failureReason.isEmpty {
            lines.append(failureReason)
        }
        return lines.joined(separator: "\n")
    }

    init(error: Error) {
        let nsError = error as NSError
        let localizedError = error as? LocalizedError

        self.domain = nsError.domain
        self.code = nsError.code
        self.message = localizedError?.errorDescription ?? nsError.localizedDescription
        self.failureReason = localizedError?.failureReason
        self.recoverySuggestion = localizedError?.recoverySuggestion
        self.codeLabel = Self.resolveCodeLabel(error: error)
    }

    private static func resolveCodeLabel(error: Error) -> String? {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .unknown:
                return "ASAuthorizationError.unknown"
            case .canceled:
                return "ASAuthorizationError.canceled"
            case .invalidResponse:
                return "ASAuthorizationError.invalidResponse"
            case .notHandled:
                return "ASAuthorizationError.notHandled"
            case .failed:
                return "ASAuthorizationError.failed"
            case .notInteractive:
                return "ASAuthorizationError.notInteractive"
            case .matchedExcludedCredential:
                return "ASAuthorizationError.matchedExcludedCredential"
            case .credentialImport:
                return "ASAuthorizationError.credentialImport"
            case .credentialExport:
                return "ASAuthorizationError.credentialExport"
            case .preferSignInWithApple:
                return "ASAuthorizationError.preferSignInWithApple"
            case .deviceNotConfiguredForPasskeyCreation:
                return "ASAuthorizationError.deviceNotConfiguredForPasskeyCreation"
            @unknown default:
                return "ASAuthorizationError.unknownFutureCase"
            }
        }

        let nsError = error as NSError
        if nsError.domain == ASWebAuthenticationSessionError.errorDomain,
           let webAuthError = ASWebAuthenticationSessionError.Code(rawValue: nsError.code) {
            switch webAuthError {
            case .canceledLogin:
                return "ASWebAuthenticationSessionError.canceledLogin"
            case .presentationContextInvalid:
                return "ASWebAuthenticationSessionError.presentationContextInvalid"
            case .presentationContextNotProvided:
                return "ASWebAuthenticationSessionError.presentationContextNotProvided"
            @unknown default:
                return "ASWebAuthenticationSessionError.unknownFutureCase"
            }
        }

        return nil
    }
}

private struct AuthDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss

    let lastAppleSignInError: AppleSignInErrorSnapshot?

    var body: some View {
        NavigationStack {
            List {
                Section("Runtime App Config") {
                    DiagnosticRow(label: "Bundle identifier", value: RuntimeAuthDiagnostics.bundleIdentifier)
                    DiagnosticRow(label: "Version", value: RuntimeAuthDiagnostics.versionString)
                    DiagnosticRow(label: "Build", value: RuntimeAuthDiagnostics.buildNumber)
                    DiagnosticRow(label: "Clerk publishable key", value: RuntimeAuthDiagnostics.publishableKeyPreview)
                }

                Section("OAuth Callback Config") {
                    DiagnosticRow(label: "Expected callback scheme", value: RuntimeAuthDiagnostics.expectedCallbackScheme)
                    DiagnosticRow(label: "Expected redirect URL", value: RuntimeAuthDiagnostics.expectedRedirectURL)
                    DiagnosticRow(label: "Configured URL schemes", value: RuntimeAuthDiagnostics.configuredURLSchemes.joined(separator: ", "))
                }

                Section("Code Signing / Entitlements") {
                    DiagnosticRow(label: "Team ID (build setting)", value: RuntimeAuthDiagnostics.buildTeamIdentifier)
                    DiagnosticRow(label: "Application identifier", value: RuntimeAuthDiagnostics.applicationIdentifier)
                    DiagnosticRow(label: "Expected Apple Sign-In modes", value: RuntimeAuthDiagnostics.appleSignInEntitlement.joined(separator: ", "))
                    DiagnosticRow(label: "Expected associated domains", value: RuntimeAuthDiagnostics.associatedDomains.joined(separator: ", "))
                }

                Section("Last Apple Sign-In Error") {
                    if let lastAppleSignInError {
                        DiagnosticRow(label: "Timestamp", value: RuntimeAuthDiagnostics.dateFormatter.string(from: lastAppleSignInError.timestamp))
                        DiagnosticRow(label: "Domain", value: lastAppleSignInError.domain)
                        DiagnosticRow(label: "Code", value: "\(lastAppleSignInError.code)")
                        DiagnosticRow(label: "Code label", value: lastAppleSignInError.codeLabel ?? "n/a")
                        DiagnosticRow(label: "Message", value: lastAppleSignInError.message)
                        DiagnosticRow(label: "Failure reason", value: lastAppleSignInError.failureReason ?? "n/a")
                        DiagnosticRow(label: "Recovery suggestion", value: lastAppleSignInError.recoverySuggestion ?? "n/a")
                    } else {
                        Text("No Apple sign-in error captured in this app launch yet.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Auth Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct DiagnosticRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value.isEmpty ? "n/a" : value)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
}

private enum RuntimeAuthDiagnostics {
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "n/a"
    }

    static var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "n/a"
    }

    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "n/a"
    }

    static var buildTeamIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: "KaiwaBuildDevelopmentTeam") as? String ?? "n/a"
    }

    static var configuredURLSchemes: [String] {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return []
        }

        return urlTypes
            .flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
            .filter { !$0.isEmpty }
    }

    static var expectedCallbackScheme: String {
        bundleIdentifier
    }

    static var expectedRedirectURL: String {
        "\(bundleIdentifier)://callback"
    }

    static var applicationIdentifier: String {
        if buildTeamIdentifier == "n/a" || bundleIdentifier == "n/a" {
            return "n/a"
        }
        return "\(buildTeamIdentifier).\(bundleIdentifier)"
    }

    static var appleSignInEntitlement: [String] {
        Bundle.main.object(forInfoDictionaryKey: "KaiwaExpectedAppleSignInModes") as? [String] ?? []
    }

    static var associatedDomains: [String] {
        Bundle.main.object(forInfoDictionaryKey: "KaiwaExpectedAssociatedDomains") as? [String] ?? []
    }

    static var publishableKeyPreview: String {
        mask(ConfigService.clerkPublishableKey)
    }

    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    private static func mask(_ value: String) -> String {
        guard value.count > 14 else { return value }
        return "\(value.prefix(10))...\(value.suffix(4))"
    }
}
