import SwiftUI

struct HistoryGlossaryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SessionViewModel

    @State private var selectedTab = 0
    @State private var newSource = ""
    @State private var newTarget = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Mode", selection: $selectedTab) {
                    Text("History").tag(0)
                    Text("Glossary").tag(1)
                }
                .pickerStyle(.segmented)

                if selectedTab == 0 {
                    historyContent
                } else {
                    glossaryContent
                }
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("History & Glossary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var historyContent: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(viewModel.sessions.count) session\(viewModel.sessions.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Button("Clear All") {
                    viewModel.clearHistory()
                }
                .font(.caption)
                .foregroundColor(.red)
            }

            ConversationTreeView(viewModel: viewModel)
        }
    }

    private var glossaryContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Source term", text: $newSource)
                    .textFieldStyle(.roundedBorder)
                TextField("Target term", text: $newTarget)
                    .textFieldStyle(.roundedBorder)
            }

            Button("Add / Update Term") {
                viewModel.addGlossaryItem(source: newSource, target: newTarget)
                newSource = ""
                newTarget = ""
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(newSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                      newTarget.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            List(viewModel.glossaryItems) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.source)
                            .foregroundColor(.white)
                        Text(item.target)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .listRowBackground(Color.black)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.removeGlossaryItem(id: item.id)
                    } label: {
                        Text("Delete")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
    }
}
