import SwiftUI
import ClerkKit

struct ContentView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = SessionViewModel()
    @State private var showingSetup = true
    @State private var showingSignIn = false
    @State private var showingHistoryGlossary = false

    var body: some View {
        Group {
            if clerk.user == nil {
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text("会話")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Real-time Translation")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Button(action: { showingSignIn = true }) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: 280)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }

                    Spacer()
                }
                .sheet(isPresented: $showingSignIn) {
                    AuthSheet()
                }
            } else {
                ZStack {
                    if showingSetup {
                        SetupView(viewModel: viewModel, isApproved: viewModel.isApproved) {
                            showingSetup = false
                        }
                    } else {
                        SessionView(viewModel: viewModel) {
                            showingSetup = true
                        }
                    }

                    VStack {
                        HStack {
                            Button(action: {
                                showingHistoryGlossary = true
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "book.closed")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                        .padding(12)

                                    if !viewModel.glossaryItems.isEmpty {
                                        Text("\(viewModel.glossaryItems.count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(minWidth: 16, minHeight: 16)
                                            .background(Circle().fill(Color.green))
                                            .offset(x: -2, y: 4)
                                    }
                                }
                            }

                            Spacer()

                            Button(action: {
                                Task {
                                    await viewModel.stopSession()
                                    try? await clerk.auth.signOut()
                                }
                            }) {
                                Image(systemName: "person.crop.circle.badge.xmark")
                                    .font(.title3)
                                    .foregroundColor(.green)
                                    .padding(12)
                            }
                        }
                        Spacer()
                    }
                }
                .task {
                    await viewModel.checkApproval()
                }
                .sheet(isPresented: $showingHistoryGlossary) {
                    HistoryGlossaryView(viewModel: viewModel)
                }
            }
        }
    }
}
