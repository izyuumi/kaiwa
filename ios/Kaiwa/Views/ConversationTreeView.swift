import SwiftUI

// MARK: - Root tree view

struct ConversationTreeView: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        if viewModel.sessions.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "rectangle.stack")
                    .font(.largeTitle)
                    .foregroundColor(.gray.opacity(0.4))
                Text("No saved sessions yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                // Pending branch banner
                if let branchId = viewModel.pendingBranchParentId,
                   let parent = viewModel.sessions.first(where: { $0.id == branchId }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Branching from:")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(parent.label ?? sessionTitle(parent))
                                .font(.caption)
                                .foregroundColor(.green)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button {
                            viewModel.clearNextSessionBranch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.green.opacity(0.08))
                }

                ForEach(ConversationSession.rootSessions(from: viewModel.sessions)) { session in
                    SessionNodeView(
                        session: session,
                        allSessions: viewModel.sessions,
                        depth: 0,
                        viewModel: viewModel
                    )
                    .listRowBackground(Color.black)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 8))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
    }
}

// MARK: - Session tree node

private struct SessionNodeView: View {
    let session: ConversationSession
    let allSessions: [ConversationSession]
    let depth: Int
    @ObservedObject var viewModel: SessionViewModel

    @State private var isExpanded = false
    @State private var showingEntries = false

    private var children: [ConversationSession] {
        session.children(in: allSessions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Session header row
            HStack(alignment: .center, spacing: 8) {
                // Depth indicator
                if depth > 0 {
                    HStack(spacing: 0) {
                        ForEach(0..<depth, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 1.5)
                                .padding(.leading, 10)
                        }
                    }
                }

                // Expand/collapse chevron (only if has children)
                if !children.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(width: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 16)
                }

                // Branch icon for non-root sessions
                if session.parentSessionId != nil {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.7))
                }

                // Session info
                Button {
                    showingEntries.toggle()
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(session.label ?? sessionTitle(session))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)

                            if !children.isEmpty {
                                Text("\(children.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.green.opacity(0.2)))
                            }
                        }

                        HStack(spacing: 6) {
                            Text("\(session.entries.count) entries")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("·")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(durationString(session.duration))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }

                        Text(session.preview)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.leading, 4)
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    viewModel.setNextSessionBranch(parentId: session.id)
                } label: {
                    Label("Branch from this session", systemImage: "arrow.turn.down.right")
                }

                Divider()

                Button(role: .destructive) {
                    viewModel.deleteSession(id: session.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            // Expanded entries
            if showingEntries && !session.entries.isEmpty {
                ForEach(session.entries.sorted { $0.timestamp < $1.timestamp }) { entry in
                    EntryRowView(entry: entry, depth: depth)
                }
                .padding(.leading, CGFloat((depth + 1) * 20))
            }

            // Child sessions (branches)
            if isExpanded {
                ForEach(children) { child in
                    SessionNodeView(
                        session: child,
                        allSessions: allSessions,
                        depth: min(depth + 1, 4),
                        viewModel: viewModel
                    )
                }
            }
        }
    }
}

// MARK: - Entry row

private struct EntryRowView: View {
    let entry: ConversationEntry
    let depth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.6))
            Text(entry.detectedLanguage.hasPrefix("ja") ? entry.jp : entry.en)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
            Text(entry.detectedLanguage.hasPrefix("ja") ? entry.en : entry.jp)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(6)
        .padding(.vertical, 2)
    }
}

// MARK: - Helpers

private func sessionTitle(_ session: ConversationSession) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: session.startedAt)
}

private func durationString(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    if minutes > 0 {
        return "\(minutes)m \(seconds)s"
    }
    return "\(seconds)s"
}
