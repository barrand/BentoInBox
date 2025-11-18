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
        // Global hotkey handlers - work regardless of focus
        .onKeyPress("1") {
            handleCategoryHotkey(priority: 1)
        }
        .onKeyPress("2") {
            handleCategoryHotkey(priority: 2)
        }
        .onKeyPress("3") {
            handleCategoryHotkey(priority: 3)
        }
        .onKeyPress("4") {
            handleCategoryHotkey(priority: 4)
        }
#if os(iOS)
        .preferredColorScheme(.dark)
#endif
    }
    
    // MARK: - Hotkey Handler
    
    private func handleCategoryHotkey(priority: Int) -> KeyPress.Result {
        guard let messageId = selectedMessageId,
              let category = categoryForPriority(priority) else {
            return .ignored
        }
        try? viewModel.assign(messageId: messageId, to: category.id, context: modelContext)
        return .handled
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
    
    private func categoryForPriority(_ priority: Int) -> CategoryDTO? {
        viewModel.categories.first { category in
            let name = category.name.lowercased()
            // Match "p1 ", "p1-", "p1:" patterns at the start of the name
            return name.hasPrefix("p\(priority) ") ||
                   name.hasPrefix("p\(priority)-") ||
                   name.hasPrefix("p\(priority):")
        }
    }
    
    private func getPriority(for category: CategoryDTO) -> Int? {
        let name = category.name.lowercased()
        // Check for "p1 ", "p1-", "p1:" patterns at the start
        if name.hasPrefix("p1 ") || name.hasPrefix("p1-") || name.hasPrefix("p1:") { return 1 }
        if name.hasPrefix("p2 ") || name.hasPrefix("p2-") || name.hasPrefix("p2:") { return 2 }
        if name.hasPrefix("p3 ") || name.hasPrefix("p3-") || name.hasPrefix("p3:") { return 3 }
        if name.hasPrefix("p4 ") || name.hasPrefix("p4-") || name.hasPrefix("p4:") { return 4 }
        return nil
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
    
    @Environment(\.gmailService) private var gmailService

    @State private var selected: CategoryDTO?
    @State private var messageBody: GmailMessageBody?
    @State private var isLoadingBody = false
    @State private var bodyLoadError: String?
    @State private var hasLoadedBody = false
    
    // Sentinel UUID for "Uncategorized" state
    private let uncategorizedID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    private func assignCategory(_ category: CategoryDTO?) {
        selected = category
        onAssign(category)
    }
    
    private func getPriority(for category: CategoryDTO) -> Int? {
        let name = category.name.lowercased()
        // Check for "p1 ", "p1-", "p1:" patterns at the start
        if name.hasPrefix("p1 ") || name.hasPrefix("p1-") || name.hasPrefix("p1:") { return 1 }
        if name.hasPrefix("p2 ") || name.hasPrefix("p2-") || name.hasPrefix("p2:") { return 2 }
        if name.hasPrefix("p3 ") || name.hasPrefix("p3-") || name.hasPrefix("p3:") { return 3 }
        if name.hasPrefix("p4 ") || name.hasPrefix("p4-") || name.hasPrefix("p4:") { return 4 }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Category badge at the top
                HStack {
                    Spacer()
                    if let cat = categories.first(where: { $0.id == message.userCategoryId }) {
                        Label {
                            Text(cat.name)
                                .font(.subheadline.weight(.medium))
                        } icon: {
                            Image(systemName: categoryIconName(for: cat))
                                .imageScale(.medium)
                                .foregroundStyle(categoryColor(for: cat))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(categoryColor(for: cat).opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Label {
                            Text("Uncategorized")
                                .font(.subheadline.weight(.medium))
                        } icon: {
                            Image(systemName: "tray")
                                .imageScale(.medium)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Divider()
                
                // Subject
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subject")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(message.subject ?? "(No subject)")
#if os(macOS)
                        .font(.title2.weight(.semibold))
#else
                        .font(.title3.weight(.semibold))
#endif
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                Divider()
                
                // Message details in a grid
                VStack(spacing: 0) {
                    MessageDetailRow(label: "From", value: message.from)
                    Divider().padding(.leading)
                    MessageDetailRow(label: "Date", value: formatDate(message.date))
                    Divider().padding(.leading)
                    MessageDetailRow(label: "Status", value: message.isRead ? "Read" : "Unread")
                }
                .background(Color(white: 0.95).opacity(0.3))
                
                Divider()
                
                // Message content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Message")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    if isLoadingBody {
                        HStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading message...")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                    } else if let error = bodyLoadError {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Failed to load full message")
                                .font(.callout)
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            // Fallback to snippet
                            if let snippet = message.snippet {
                                Divider()
                                    .padding(.vertical, 4)
                                Text("Preview:")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(snippet)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                    .textSelection(.enabled)
                            }
                        }
                    } else if let body = messageBody {
                        // Render HTML if available, otherwise show plain text
                        if body.hasHTML, let html = body.html {
                            HTMLEmailView(htmlContent: html)
                                .frame(minHeight: 200)
                        } else if body.hasPlainText, let plain = body.plain {
                            Text(plain)
#if os(macOS)
                                .font(.body)
#else
                                .font(.callout)
#endif
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        } else {
                            Text("(No content available)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        // Fallback to snippet while loading
                        Text(message.snippet ?? "(No preview available)")
#if os(macOS)
                            .font(.body)
#else
                            .font(.callout)
#endif
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                Divider()
                
                // Category assignment section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Assign Category")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Text("Hotkeys: 1-4")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Picker("Category", selection: Binding(
                        get: { selected?.id ?? message.userCategoryId ?? uncategorizedID },
                        set: { newValue in
                            if newValue == uncategorizedID {
                                assignCategory(nil)
                            } else {
                                let category = categories.first(where: { $0.id == newValue })
                                assignCategory(category)
                            }
                        })
                    ) {
                        Label("Uncategorized", systemImage: "tray").tag(uncategorizedID)
                        ForEach(categories) { c in
                            HStack {
                                Label {
                                    Text(c.name)
                                } icon: {
                                    Image(systemName: categoryIconName(for: c))
                                        .imageScale(.medium)
                                        .foregroundStyle(categoryColor(for: c))
                                }
                                if let priority = getPriority(for: c) {
                                    Spacer()
                                    Text("\(priority)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(3)
                                }
                            }
                            .tag(c.id)
                        }
                    }
#if os(macOS)
                    .pickerStyle(.menu)
                    .controlSize(.large)
#else
                    .pickerStyle(.menu)
#endif
                }
                .padding()
            }
        }
        .navigationTitle("Message")
        .onAppear {
            selected = categories.first(where: { $0.id == message.userCategoryId })
            // Auto-load full message on appear
            if !hasLoadedBody {
                Task {
                    await loadFullMessage()
                }
            }
        }
        .onChange(of: message.id) { _, newId in
            // Reset and load when message changes
            messageBody = nil
            bodyLoadError = nil
            hasLoadedBody = false
            Task {
                await loadFullMessage()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadFullMessage() async {
        guard !hasLoadedBody else { return }
        
        isLoadingBody = true
        bodyLoadError = nil
        
        do {
            let body = try await gmailService.getMessageBody(id: message.id)
            messageBody = body
            hasLoadedBody = true
        } catch {
            bodyLoadError = error.localizedDescription
        }
        
        isLoadingBody = false
    }
}

// Helper view for detail rows
struct MessageDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
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

// MARK: - HTML Email Viewer

#if os(macOS)
import WebKit

struct HTMLEmailView: NSViewRepresentable {
    let htmlContent: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground") // Transparent background
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: #000;
                    margin: 0;
                    padding: 16px;
                    background: transparent;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    display: none; /* Hide images as requested */
                }
                a {
                    color: #007AFF;
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
                }
                blockquote {
                    border-left: 3px solid #ccc;
                    margin-left: 0;
                    padding-left: 16px;
                    color: #666;
                }
                pre, code {
                    background: #f5f5f5;
                    padding: 2px 4px;
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, Menlo, monospace;
                    font-size: 13px;
                }
                pre {
                    padding: 12px;
                    overflow-x: auto;
                }
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}
#else
import WebKit

struct HTMLEmailView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    color: #000;
                    margin: 0;
                    padding: 16px;
                    background: transparent;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    display: none; /* Hide images as requested */
                }
                a {
                    color: #007AFF;
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
                }
                blockquote {
                    border-left: 3px solid #ccc;
                    margin-left: 0;
                    padding-left: 16px;
                    color: #666;
                }
                pre, code {
                    background: #f5f5f5;
                    padding: 2px 4px;
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, Menlo, monospace;
                    font-size: 14px;
                }
                pre {
                    padding: 12px;
                    overflow-x: auto;
                }
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}
#endif

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
