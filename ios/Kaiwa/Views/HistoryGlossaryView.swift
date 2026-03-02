import SwiftUI

struct HistoryGlossaryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SessionViewModel

    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var newSource = ""
    @State private var newTarget = ""

    /// Called when user wants to start a new session branching from history.
    var onBranchSelected: (() -> Void)?

    private var filteredHistory: [ConversationEntry] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return viewModel.historyEntries }
        return viewModel.historyEntries.filter {
            $0.jp.localizedCaseInsensitiveContains(q) ||
            $0.en.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Mode", selection: $selectedTab) {
                    Text("Sessions").tag(0)
                    Text("History").tag(1)
                    Text("Glossary").tag(2)
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case 0:
                    BranchTreeView(viewModel: viewModel) {
                        dismiss()
                        onBranchSelected?()
                    }
                case 1:
                    historyContent
                default:
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
            TextField("Search history", text: $searchText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("\(viewModel.historyEntries.count) entries")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Button("Clear All") {
                    viewModel.clearHistory()
                }
                .font(.caption)
                .foregroundColor(.red)
            }

            List(filteredHistory) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("\(entry.jp)  ↔  \(entry.en)")
                        .foregroundColor(.white)
                        .font(.body)
                        .lineLimit(4)
                }
                .listRowBackground(Color.black)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.removeHistoryEntry(id: entry.id)
                    } label: {
                        Text("Delete")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
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
