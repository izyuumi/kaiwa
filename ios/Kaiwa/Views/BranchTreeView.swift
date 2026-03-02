import SwiftUI

// MARK: – Branch Tree View

struct BranchTreeView: View {
    @ObservedObject var viewModel: SessionViewModel
    /// Called when the user wants to start a new session branching from a specific entry.
    let onBranchSelected: () -> Void

    @State private var expandedBranchIds: Set<UUID> = []
    @State private var branchToDelete: ConversationBranch?
    @State private var showingDeleteConfirm = false
    @State private var selectedBranchForDetail: ConversationBranch?

    private var treeNodes: [BranchNode] {
        viewModel.branches.buildTree()
    }

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.branches.isEmpty {
                emptyState
            } else {
                HStack {
                    Text("\(viewModel.branches.count) session\(viewModel.branches.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(treeNodes) { node in
                            BranchNodeRow(
                                node: node,
                                depth: 0,
                                expandedIds: $expandedBranchIds,
                                onSelect: { branch in
                                    selectedBranchForDetail = branch
                                },
                                onDelete: { branch in
                                    branchToDelete = branch
                                    showingDeleteConfirm = true
                                }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .alert("Delete Session?", isPresented: $showingDeleteConfirm, presenting: branchToDelete) { branch in
            Button("Delete", role: .destructive) {
                viewModel.deleteBranch(id: branch.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { branch in
            Text("\u{201C}\(branch.name)\u{201D} and any branches from it will be deleted.")
        }
        .sheet(item: $selectedBranchForDetail) { branch in
            BranchDetailView(
                branch: branch,
                viewModel: viewModel,
                onBranchFromEntry: { entry in
                    viewModel.prepareBranchSetup(from: entry, in: branch)
                    selectedBranchForDetail = nil
                    onBranchSelected()
                }
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))
            Text("No sessions yet")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Completed sessions appear here as a tree.\nBranch from any message to explore alternatives.")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: – Branch Node Row

private struct BranchNodeRow: View {
    let node: BranchNode
    let depth: Int
    @Binding var expandedIds: Set<UUID>
    let onSelect: (ConversationBranch) -> Void
    let onDelete: (ConversationBranch) -> Void

    private var isExpanded: Bool {
        expandedIds.contains(node.id)
    }

    private var hasChildren: Bool {
        !node.children.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            branchRow
            if isExpanded {
                ForEach(node.children) { child in
                    BranchNodeRow(
                        node: child,
                        depth: depth + 1,
                        expandedIds: $expandedIds,
                        onSelect: onSelect,
                        onDelete: onDelete
                    )
                }
            }
        }
    }

    private var branchRow: some View {
        HStack(spacing: 0) {
            // Indentation + connector lines
            if depth > 0 {
                HStack(spacing: 0) {
                    ForEach(0..<depth, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1)
                            .padding(.leading, 12)
                            .padding(.trailing, 11)
                    }
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.trailing, 4)
                }
            }

            Button {
                onSelect(node.branch)
            } label: {
                HStack(spacing: 10) {
                    // Branch icon
                    Image(systemName: depth == 0 ? "bubble.left.and.bubble.right" : "arrow.branch")
                        .font(.caption)
                        .foregroundColor(depth == 0 ? .green : .orange)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(node.branch.name)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text("\(node.branch.entries.count) entries")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            if hasChildren {
                                Text("• \(node.children.count) branch\(node.children.count == 1 ? "" : "es")")
                                    .font(.caption2)
                                    .foregroundColor(.orange.opacity(0.8))
                            }
                        }
                    }

                    Spacer()

                    // Expand/collapse if has children
                    if hasChildren {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isExpanded {
                                    expandedIds.remove(node.id)
                                } else {
                                    expandedIds.insert(node.id)
                                }
                            }
                        } label: {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    onDelete(node.branch)
                } label: {
                    Label("Delete Session", systemImage: "trash")
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: – Branch Detail View

struct BranchDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let branch: ConversationBranch
    @ObservedObject var viewModel: SessionViewModel
    let onBranchFromEntry: (ConversationEntry) -> Void

    @State private var searchText = ""

    private var filteredEntries: [ConversationEntry] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return branch.entries }
        return branch.entries.filter {
            $0.jp.localizedCaseInsensitiveContains(q) ||
            $0.en.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                // Branch metadata
                branchMetaCard

                TextField("Search entries…", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                List(filteredEntries) { entry in
                    entryRow(entry)
                        .listRowBackground(Color.black)
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(branch.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var branchMetaCard: some View {
        HStack(spacing: 12) {
            Image(systemName: branch.parentBranchId == nil ? "bubble.left.and.bubble.right" : "arrow.branch")
                .font(.title3)
                .foregroundColor(branch.parentBranchId == nil ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(branch.createdAt, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("\(branch.entries.count) entries")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    private func entryRow(_ entry: ConversationEntry) -> some View {
        let isJP = entry.detectedLanguage.hasPrefix("ja")
        let original = isJP ? entry.jp : entry.en
        let translated = isJP ? entry.en : entry.jp

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
                Text(isJP ? "JP" : "EN")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .foregroundColor(.white.opacity(0.7))
            }
            Text("\(original)  →  \(translated)")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .lineLimit(4)
        }
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
            Divider()
            Button {
                onBranchFromEntry(entry)
            } label: {
                Label("Branch from Here", systemImage: "arrow.branch")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                onBranchFromEntry(entry)
            } label: {
                Label("Branch", systemImage: "arrow.branch")
            }
            .tint(.orange)
        }
    }
}
