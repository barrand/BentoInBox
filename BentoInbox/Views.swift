//
//  Views.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import SwiftUI
import SwiftData

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.authService) private var authService

    @StateObject var viewModel: SignInViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("BentoInBox")
                .font(.largeTitle.weight(.bold))
            Text("Sign in to your Google account to fetch your Inbox (read-only).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button {
                Task { await viewModel.signIn(authService: authService, appState: appState) }
            } label: {
                if viewModel.isSigningIn {
                    ProgressView()
                } else {
                    Text("Sign in with Google (Mock)")
                }
            }
            .buttonStyle(.borderedProminent)

            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red)
            }
        }
        .padding()
#if os(iOS)
        .preferredColorScheme(.dark)
#endif
    }
}

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.gmailService) private var gmailService

    @StateObject var viewModel: InboxViewModel

    // Selection drives the detail pane on macOS and wide layouts.
    @State private var selectedMessageId: String? = nil

    // Control split view visibility to prefer both columns on wide screens.
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detailPane
        }
        .onChange(of: viewModel.messages.map(\.id)) { _, _ in }
        .task {
            columnVisibility = .automatic
            try? SeedCategoryLoader.seedIfNeeded(modelContext)
            try? viewModel.load(context: modelContext)
            await viewModel.refresh(context: modelContext, gmail: gmailService)
            selectedMessageId = nil
        }
#if os(iOS)
        .preferredColorScheme(.dark)
#endif
    }

    // MARK: - Sidebar (List + Filters)

    private var sidebar: some View {
        List(selection: $selectedMessageId) {
            ForEach(viewModel.messages) { msg in
                MessageRow(message: msg, categories: viewModel.categories)
                    .tag(msg.id)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Menu("Assign Category") {
                            Button {
                                try? viewModel.assign(messageId: msg.id, to: nil, context: modelContext)
                            } label: {
                                Label("Uncategorized", systemImage: "tray")
                            }
                            ForEach(viewModel.categories) { cat in
                                Button {
                                    try? viewModel.assign(messageId: msg.id, to: cat.id, context: modelContext)
                                } label: {
                                    Label {
                                        Text(cat.name)
                                    } icon: {
                                        Image(systemName: categoryIconName(for: cat))
                                            .imageScale(.medium)
                                            .foregroundStyle(categoryColor(for: cat))
                                    }
                                }
                            }
                        }
                    }
#if os(macOS)
                    .controlSize(.large)
#endif
            }
        }
        .listStyle(.inset)
        .overlay {
            if viewModel.isRefreshing {
                ProgressView().controlSize(.large)
            }
        }
        .navigationTitle("Inbox")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 240, ideal: 300)
#endif
        .toolbar {
            ToolbarItemGroup {
                Picker("Filter", selection: Binding(
                    get: { filterTag(viewModel.filter) },
                    set: { tag in
                        viewModel.filter = filterFromTag(tag)
                        try? viewModel.load(context: modelContext)
                        selectedMessageId = nil
                    })
                ) {
                    Label("All", systemImage: "tray.full").tag("all")
                    Label("Uncategorized", systemImage: "tray").tag("uncat")
                    if !viewModel.categories.isEmpty {
                        Divider()
                        ForEach(viewModel.categories) { category in
                            Label {
                                Text(category.name)
                            } icon: {
                                Image(systemName: categoryIconName(for: category))
                                    .imageScale(.medium)
                                    .foregroundStyle(categoryColor(for: category))
                            }
                            .tag(category.id.uuidString)
                        }
                    }
                }
                .pickerStyle(.menu)
#if os(macOS)
                .controlSize(.large)
#endif

                Button {
                    Task {
                        await viewModel.refresh(context: modelContext, gmail: gmailService)
                        if selectedMessageId != nil,
                           !viewModel.messages.contains(where: { $0.id == selectedMessageId }) {
                            selectedMessageId = nil
                        }
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                NavigationLink {
                    CategoriesView()
                } label: {
                    Label("Categories", systemImage: "tag")
                }
            }
        }
    }

    // MARK: - Detail Pane

    private var detailPane: some View {
        Group {
            if let sel = selectedMessageId,
               let msg = viewModel.messages.first(where: { $0.id == sel }) {
                MessageDetailView(
                    message: msg,
                    categories: viewModel.categories
                ) { cat in
                    try? viewModel.assign(messageId: msg.id, to: cat?.id, context: modelContext)
                }
                .navigationTitle(msg.subject ?? "Message")
#if os(macOS)
                .controlSize(.large)
#endif
            } else {
                Text("Select a message")
                    .foregroundStyle(.secondary)
#if os(macOS)
                    .font(.title3)
#endif
            }
        }
    }

    // MARK: - Helpers

    private func filterTag(_ filter: InboxViewModel.InboxFilter) -> String {
        switch filter {
        case .all: return "all"
        case .uncategorized: return "uncat"
        case .category(let id): return id.uuidString
        }
    }

    private func filterFromTag(_ tag: String) -> InboxViewModel.InboxFilter {
        if tag == "all" { return .all }
        if tag == "uncat" { return .uncategorized }
        if let uuid = UUID(uuidString: tag) { return .category(uuid) }
        return .all
    }
}

struct MessageRow: View {
    let message: MessageDTO
    let categories: [CategoryDTO]

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(message.isRead ? Color.clear : Color.accentColor)
#if os(macOS)
                .frame(width: 10, height: 10)
#else
                .frame(width: 8, height: 8)
#endif
            VStack(alignment: .leading, spacing: 3) {
                Text(message.subject ?? "(No subject)")
#if os(macOS)
                    .font(.title3.weight(.semibold))
#else
                    .font(.headline)
#endif
                    .lineLimit(1)
                Text(message.snippet ?? "")
#if os(macOS)
                    .font(.body)
#else
                    .font(.subheadline)
#endif
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let cat = categories.first(where: { $0.id == message.userCategoryId }) {
                Label {
                    Text(cat.name)
#if os(macOS)
                        .font(.caption)
#else
                        .font(.caption2)
#endif
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: categoryIconName(for: cat))
                        .imageScale(.medium)
                        .foregroundStyle(categoryColor(for: cat))
                }
#if os(macOS)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
#else
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
#endif
                .background(Color.clear)
            }
        }
    }
}

struct MessageDetailView: View {
    let message: MessageDTO
    let categories: [CategoryDTO]
    let onAssign: (CategoryDTO?) -> Void

    @State private var selected: CategoryDTO?

    var body: some View {
        Form {
            Section("Headers") {
                Text("From: \(message.from)")
                Text("Subject: \(message.subject ?? "(No subject)")")
            }
            Section("Snippet") {
                Text(message.snippet ?? "")
#if os(macOS)
                    .font(.title3)
#else
                    .font(.body)
#endif
            }
            Section("Category") {
                Picker("Assign", selection: Binding(
                    get: { selected?.id ?? message.userCategoryId ?? UUID() },
                    set: { newValue in
                        selected = categories.first(where: { $0.id == newValue })
                        onAssign(selected)
                    })
                ) {
                    Label("Uncategorized", systemImage: "tray").tag(UUID())
                    ForEach(categories) { c in
                        Label {
                            Text(c.name)
                        } icon: {
                            Image(systemName: categoryIconName(for: c))
                                .imageScale(.medium)
                                .foregroundStyle(categoryColor(for: c))
                        }
                        .tag(c.id)
                    }
                }
#if os(macOS)
                .controlSize(.large)
#endif
            }
        }
        .navigationTitle("Message")
        .onAppear {
            selected = categories.first(where: { $0.id == message.userCategoryId })
        }
    }
}

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CategoriesViewModel()

    var body: some View {
        List {
            ForEach(viewModel.categories) { c in
                HStack(spacing: 10) {
                    ZStack {
                        // Neutral background; only icon is colored
                        Circle()
                            .fill(Color.secondary.opacity(0.15))
#if os(macOS)
                            .frame(width: 28, height: 28)
#else
                            .frame(width: 24, height: 24)
#endif
                        Image(systemName: categoryIconName(for: c))
                            .imageScale(.medium)
                            .foregroundStyle(categoryColor(for: c))
                    }
                    Text(c.name)
#if os(macOS)
                        .font(.title3)
#else
                        .font(.body)
#endif
                    Spacer()
                    if c.isSystem {
                        Text("System")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .task {
            try? viewModel.load(context: modelContext)
        }
#if os(iOS)
        .preferredColorScheme(.dark)
#endif
    }
}

#Preview("Inbox") {
    let container = try! ModelContainer(for: Message.self, Category.self, TrainingExample.self, SyncState.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let appState = AppState()
    appState.isSignedIn = true
    return InboxView(viewModel: InboxViewModel())
        .environment(appState)
        .environment(\.authService, MockAuthService())
        .environment(\.gmailService, MockGmailService())
        .modelContainer(container)
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0x123456789ABCDEF : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private extension Color {
    // Parse #RRGGBB or RRGGBB
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        guard hexString.count == 6,
              let value = UInt64(hexString, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
