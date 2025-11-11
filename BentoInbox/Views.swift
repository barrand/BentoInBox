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
    }
}

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.gmailService) private var gmailService

    @StateObject var viewModel: InboxViewModel
    @State private var selectedCategory: CategoryDTO?

    var body: some View {
        NavigationSplitView {
            VStack {
                Picker("Filter", selection: Binding(
                    get: { filterTag(viewModel.filter) },
                    set: { tag in
                        viewModel.filter = filterFromTag(tag)
                        try? viewModel.load(context: modelContext)
                    })
                ) {
                    Text("All").tag("all")
                    Text("Uncategorized").tag("uncat")
                    ForEach(viewModel.categories) { category in
                        Text(category.name).tag(category.id.uuidString)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.top, .horizontal])

                List(viewModel.messages) { msg in
                    NavigationLink {
                        MessageDetailView(message: msg, categories: viewModel.categories) { cat in
                            try? viewModel.assign(messageId: msg.id, to: cat?.id, context: modelContext)
                        }
                    } label: {
                        MessageRow(message: msg, categories: viewModel.categories)
                    }
                }
                .listStyle(.inset)
                .overlay {
                    if viewModel.isRefreshing {
                        ProgressView().controlSize(.large)
                    }
                }
            }
            .navigationTitle("Inbox")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 240, ideal: 300)
#endif
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        Task { await viewModel.refresh(context: modelContext, gmail: gmailService) }
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
            .task {
                try? SeedCategoryLoader.seedIfNeeded(modelContext)
                try? viewModel.load(context: modelContext)
                await viewModel.refresh(context: modelContext, gmail: gmailService)
            }
        } detail: {
            Text("Select a message")
        }
    }

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
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(message.isRead ? Color.clear : Color.accentColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(message.subject ?? "(No subject)")
                    .font(.headline)
                    .lineLimit(1)
                Text(message.snippet ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let cat = categories.first(where: { $0.id == message.userCategoryId }) {
                Text(cat.name)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.thinMaterial, in: Capsule())
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
                    .font(.body)
            }
            Section("Category") {
                Picker("Assign", selection: Binding(
                    get: { selected?.id ?? message.userCategoryId ?? UUID() },
                    set: { newValue in
                        selected = categories.first(where: { $0.id == newValue })
                        onAssign(selected)
                    })
                ) {
                    Text("Uncategorized").tag(UUID())
                    ForEach(categories) { c in
                        Text(c.name).tag(c.id)
                    }
                }
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
                HStack {
                    Text(c.name)
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

