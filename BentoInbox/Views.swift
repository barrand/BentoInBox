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
                    Text("Sign in with Google")
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
    @Environment(\.authService) private var authService
    @Environment(AppState.self) private var appState

    @StateObject var viewModel: InboxViewModel
    @State private var signInVM = SignInViewModel()

    // Selection drives the detail pane on macOS and wide layouts.
    @State private var selectedMessageId: String? = nil

    // Control split view visibility to prefer both columns on wide screens.
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    // User email for display
    @State private var userEmail: String?

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
            userEmail = await gmailService.currentUserEmail()
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
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .navigationTitle("Inbox")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 240, ideal: 300)
#endif
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
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
                
                NavigationLink {
                    TrainingView()
                } label: {
                    Label("Train Model", systemImage: "brain")
                }
                
                Menu {
                    if let email = userEmail {
                        Text(email)
                            .font(.caption)
                    }
                    Divider()
                    Button(role: .destructive) {
                        Task {
                            await signInVM.signOut(authService: authService, appState: appState)
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Label("Account", systemImage: "person.circle")
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
    
    // Sentinel UUID for "Uncategorized" state
    private let uncategorizedID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

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
                    get: { selected?.id ?? message.userCategoryId ?? uncategorizedID },
                    set: { newValue in
                        if newValue == uncategorizedID {
                            selected = nil
                            onAssign(nil)
                        } else {
                            selected = categories.first(where: { $0.id == newValue })
                            onAssign(selected)
                        }
                    })
                ) {
                    Label("Uncategorized", systemImage: "tray").tag(uncategorizedID)
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
    @State private var showingResetConfirmation = false

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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingResetConfirmation = true
                } label: {
                    Label("Reset to P1-P4", systemImage: "arrow.clockwise")
                }
            }
        }
        .alert("Reset Categories?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                do {
                    try SeedCategoryLoader.resetToP1P4System(modelContext)
                    try viewModel.load(context: modelContext)
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        } message: {
            Text("This will delete all existing categories and replace them with the P1-P4 priority system. Existing email categorizations will be cleared.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            try? viewModel.load(context: modelContext)
        }
#if os(iOS)
        .preferredColorScheme(.dark)
#endif
    }
}

struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Message> { $0.userCategoryId == nil }, sort: \Message.date, order: .reverse)
    private var uncategorizedMessages: [Message]
    
    @State private var currentIndex = 0
    
    var body: some View {
        VStack {
            if uncategorizedMessages.isEmpty {
                Text("No uncategorized messages")
                    .font(.title)
                    .foregroundStyle(.secondary)
            } else if currentIndex < uncategorizedMessages.count {
                let message = uncategorizedMessages[currentIndex]
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Email \(currentIndex + 1) of \(uncategorizedMessages.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(message.date, style: .date)
                            Text(message.date, style: .time)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("From:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(message.from)
                                .font(.body)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(message.subject ?? "(No subject)")
                                .font(.headline)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(message.snippet ?? "(No content)")
                                .font(.body)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                
                HStack {
                    Button("Previous") {
                        if currentIndex > 0 {
                            currentIndex -= 1
                        }
                    }
                    .disabled(currentIndex == 0)
                    
                    Spacer()
                    
                    Button("Next") {
                        if currentIndex < uncategorizedMessages.count - 1 {
                            currentIndex += 1
                        }
                    }
                    .disabled(currentIndex >= uncategorizedMessages.count - 1)
                }
                .padding()
            } else {
                Text("All done!")
                    .font(.title)
            }
        }
        .navigationTitle("Train Model")
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
