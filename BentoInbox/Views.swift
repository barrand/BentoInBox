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
                                    Label(cat.name, systemImage: iconName(for: cat))
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
                            Label(category.name, systemImage: iconName(for: category))
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

    // 1) Name-based icon mapping for common categories.
    // 2) Otherwise pick a deterministic icon from a large curated set based on UUID.
    private func iconName(for category: CategoryDTO) -> String {
        let name = category.name.lowercased()
        switch name {
        case "uncategorized", "none", "other": return "tray"
        case "work", "office": return "briefcase.fill"
        case "personal", "home": return "person.fill"
        case "family": return "person.2.fill"
        case "friends": return "person.3.fill"
        case "finance", "bills", "receipts": return "dollarsign.circle.fill"
        case "shopping", "purchases": return "bag.fill"
        case "travel", "flights", "trips": return "airplane"
        case "news": return "newspaper.fill"
        case "social": return "at"
        case "updates", "alerts": return "bell.badge.fill"
        case "promotions", "ads", "marketing": return "sparkles"
        case "github", "dev", "code", "engineering": return "chevron.left.slash.chevron.right"
        case "health", "medical": return "heart.fill"
        case "fitness", "exercise": return "figure.run"
        case "food", "restaurants": return "fork.knife"
        case "music": return "music.note"
        case "events", "calendar": return "calendar"
        case "education", "school": return "book.fill"
        case "utilities": return "wrench.and.screwdriver.fill"
        case "support", "tickets": return "lifepreserver"
        case "photos", "images": return "photo.fill.on.rectangle.fill"
        case "videos", "media": return "film.fill"
        case "security": return "lock.shield.fill"
        case "travel docs", "boarding": return "doc.plaintext.fill"
        default:
            // Large curated set to avoid generic squares and minimize repeats
            let curated = [
                "bolt.fill","leaf.fill","globe","cloud.fill","sun.max.fill","moon.stars.fill","flame.fill",
                "paperplane.fill","envelope.fill","bookmark.fill","flag.fill","map.fill","pin.fill",
                "mappin.and.ellipse","location.fill","car.fill","tram.fill","bicycle","scooter","bus.fill",
                "train.side.front.car","ferry.fill","airpods.gen3","headphones","book.closed.fill",
                "doc.richtext.fill","doc.text.image","tray.full.fill","archivebox.fill","shippingbox.fill",
                "shippingbox.circle.fill","creditcard.fill","gift.fill","bag.badge.plus","cart.fill",
                "tag.fill","ticket.fill","theatermasks.fill","gamecontroller.fill","puzzlepiece.fill",
                "cpu.fill","antenna.radiowaves.left.and.right","network","wifi","bolt.horizontal.fill",
                "printer.fill","scanner.fill","signature","wand.and.stars","list.bullet.rectangle.fill",
                "chart.bar.fill","chart.pie.fill","chart.xyaxis.line","gauge.with.dots.needle.bottom.50percent",
                "speedometer","checkmark.seal.fill","star.circle.fill","medal.fill","rosette","trophy.fill",
                "sparkle.magnifyingglass","magnifyingglass","paperclip","link","shield.checkered",
                "hand.thumbsup.fill","hand.raised.fill","hands.sparkles.fill","message.fill","bubble.left.fill",
                "bubbles.and.sparkles.fill","bell.fill","bell.badge","bell.circle.fill","megaphone.fill",
                "mail.stack","calendar.badge.clock","clock.fill","alarm.fill","hourglass","tray.and.arrow.down.fill",
                "arrow.up.doc.fill","externaldrive.fill","internaldrive.fill","server.rack","folder.fill",
                "folder.badge.person.crop","folder.badge.gearshape","building.columns.fill","house.fill",
                "house.and.flag.fill","sparkles.square.fill","square.grid.2x2.fill","square.grid.3x1.below.rectangle.fill"
            ]
            let idx = abs(category.id.hashValue) % curated.count
            return curated[idx]
        }
    }

    private func color(for category: CategoryDTO) -> Color {
        if let hex = category.colorHex, let c = Color(hex: hex) {
            return c
        }
        // Palette of distinct, accessible colors to minimize repeats.
        let palette: [Color] = [
            Color(red: 0.93, green: 0.33, blue: 0.31), // red
            Color(red: 0.98, green: 0.62, blue: 0.20), // orange
            Color(red: 1.00, green: 0.80, blue: 0.20), // yellow
            Color(red: 0.40, green: 0.76, blue: 0.65), // teal
            Color(red: 0.20, green: 0.60, blue: 0.86), // blue
            Color(red: 0.56, green: 0.47, blue: 0.80), // purple
            Color(red: 0.55, green: 0.76, blue: 0.29), // green
            Color(red: 0.90, green: 0.49, blue: 0.13), // amber
            Color(red: 0.67, green: 0.33, blue: 0.33), // brown
            Color(red: 0.76, green: 0.21, blue: 0.48), // pink
            Color(red: 0.35, green: 0.35, blue: 0.35), // gray
            Color(red: 0.23, green: 0.50, blue: 0.43), // dark teal
            Color(red: 0.12, green: 0.47, blue: 0.71), // deep blue
            Color(red: 0.68, green: 0.78, blue: 0.28), // lime
            Color(red: 0.40, green: 0.60, blue: 0.90), // sky
            Color(red: 0.80, green: 0.70, blue: 0.90), // lavender
            Color(red: 1.00, green: 0.60, blue: 0.60), // light red
            Color(red: 0.50, green: 0.80, blue: 0.80), // aqua
            Color(red: 0.90, green: 0.80, blue: 0.50), // sand
            Color(red: 0.80, green: 0.50, blue: 0.60), // mauve
            Color(red: 0.70, green: 0.50, blue: 0.40), // cocoa
            Color(red: 0.50, green: 0.70, blue: 0.50), // sage
            Color(red: 0.60, green: 0.50, blue: 0.70), // plum
            Color(red: 0.50, green: 0.60, blue: 0.80)  // steel
        ]
        let idx = abs(category.id.hashValue) % palette.count
        let base = palette[idx]
        return base
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
                    Image(systemName: iconName(for: cat))
#if os(macOS)
                        .imageScale(.medium)
#else
                        .imageScale(.small)
#endif
                        .foregroundStyle(.primary)
                }
#if os(macOS)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
#else
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
#endif
                .background(color(for: cat).opacity(0.25), in: Capsule())
                .overlay(
                    Capsule().stroke(color(for: cat).opacity(0.7), lineWidth: 1)
                )
            }
        }
    }

    // Local helpers so MessageRow compiles independently of InboxView/CategoriesView
    private func iconName(for category: CategoryDTO) -> String {
        let name = category.name.lowercased()
        switch name {
        case "uncategorized", "none", "other": return "tray"
        case "work", "office": return "briefcase.fill"
        case "personal", "home": return "person.fill"
        case "family": return "person.2.fill"
        case "friends": return "person.3.fill"
        case "finance", "bills", "receipts": return "dollarsign.circle.fill"
        case "shopping", "purchases": return "bag.fill"
        case "travel", "flights", "trips": return "airplane"
        case "news": return "newspaper.fill"
        case "social": return "at"
        case "updates", "alerts": return "bell.badge.fill"
        case "promotions", "ads", "marketing": return "sparkles"
        case "github", "dev", "code", "engineering": return "chevron.left.slash.chevron.right"
        case "health", "medical": return "heart.fill"
        case "fitness", "exercise": return "figure.run"
        case "food", "restaurants": return "fork.knife"
        case "music": return "music.note"
        case "events", "calendar": return "calendar"
        case "education", "school": return "book.fill"
        case "utilities": return "wrench.and.screwdriver.fill"
        case "support", "tickets": return "lifepreserver"
        case "photos", "images": return "photo.fill.on.rectangle.fill"
        case "videos", "media": return "film.fill"
        case "security": return "lock.shield.fill"
        case "travel docs", "boarding": return "doc.plaintext.fill"
        default:
            let curated = [
                "bolt.fill","leaf.fill","globe","cloud.fill","sun.max.fill","moon.stars.fill","flame.fill",
                "paperplane.fill","envelope.fill","bookmark.fill","flag.fill","map.fill","pin.fill",
                "mappin.and.ellipse","location.fill","car.fill","tram.fill","bicycle","scooter","bus.fill",
                "train.side.front.car","ferry.fill","airpods.gen3","headphones","book.closed.fill",
                "doc.richtext.fill","doc.text.image","tray.full.fill","archivebox.fill","shippingbox.fill",
                "shippingbox.circle.fill","creditcard.fill","gift.fill","bag.badge.plus","cart.fill",
                "tag.fill","ticket.fill","theatermasks.fill","gamecontroller.fill","puzzlepiece.fill",
                "cpu.fill","antenna.radiowaves.left.and.right","network","wifi","bolt.horizontal.fill",
                "printer.fill","scanner.fill","signature","wand.and.stars","list.bullet.rectangle.fill",
                "chart.bar.fill","chart.pie.fill","chart.xyaxis.line","gauge.with.dots.needle.bottom.50percent",
                "speedometer","checkmark.seal.fill","star.circle.fill","medal.fill","rosette","trophy.fill",
                "sparkle.magnifyingglass","magnifyingglass","paperclip","link","shield.checkered",
                "hand.thumbsup.fill","hand.raised.fill","hands.sparkles.fill","message.fill","bubble.left.fill",
                "bubbles.and.sparkles.fill","bell.fill","bell.badge","bell.circle.fill","megaphone.fill",
                "mail.stack","calendar.badge.clock","clock.fill","alarm.fill","hourglass","tray.and.arrow.down.fill",
                "arrow.up.doc.fill","externaldrive.fill","internaldrive.fill","server.rack","folder.fill",
                "folder.badge.person.crop","folder.badge.gearshape","building.columns.fill","house.fill",
                "house.and.flag.fill","sparkles.square.fill","square.grid.2x2.fill","square.grid.3x1.below.rectangle.fill"
            ]
            let idx = abs(category.id.hashValue) % curated.count
            return curated[idx]
        }
    }

    private func color(for category: CategoryDTO) -> Color {
        if let hex = category.colorHex, let c = Color(hex: hex) {
            return c
        }
        let palette: [Color] = [
            Color(red: 0.93, green: 0.33, blue: 0.31),
            Color(red: 0.98, green: 0.62, blue: 0.20),
            Color(red: 1.00, green: 0.80, blue: 0.20),
            Color(red: 0.40, green: 0.76, blue: 0.65),
            Color(red: 0.20, green: 0.60, blue: 0.86),
            Color(red: 0.56, green: 0.47, blue: 0.80),
            Color(red: 0.55, green: 0.76, blue: 0.29),
            Color(red: 0.90, green: 0.49, blue: 0.13),
            Color(red: 0.67, green: 0.33, blue: 0.33),
            Color(red: 0.76, green: 0.21, blue: 0.48),
            Color(red: 0.35, green: 0.35, blue: 0.35),
            Color(red: 0.23, green: 0.50, blue: 0.43),
            Color(red: 0.12, green: 0.47, blue: 0.71),
            Color(red: 0.68, green: 0.78, blue: 0.28),
            Color(red: 0.40, green: 0.60, blue: 0.90),
            Color(red: 0.80, green: 0.70, blue: 0.90),
            Color(red: 1.00, green: 0.60, blue: 0.60),
            Color(red: 0.50, green: 0.80, blue: 0.80),
            Color(red: 0.90, green: 0.80, blue: 0.50),
            Color(red: 0.80, green: 0.50, blue: 0.60),
            Color(red: 0.70, green: 0.50, blue: 0.40),
            Color(red: 0.50, green: 0.70, blue: 0.50),
            Color(red: 0.60, green: 0.50, blue: 0.70),
            Color(red: 0.50, green: 0.60, blue: 0.80)
        ]
        let idx = abs(category.id.hashValue) % palette.count
        return palette[idx]
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
                        Label(c.name, systemImage: iconName(for: c)).tag(c.id)
                    }
                }
                .tint(selected.flatMap { color(for: $0) } ?? .accentColor)
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

    // Local helpers to fix missing scope errors
    private func iconName(for category: CategoryDTO) -> String {
        let name = category.name.lowercased()
        switch name {
        case "uncategorized", "none", "other": return "tray"
        case "work", "office": return "briefcase.fill"
        case "personal", "home": return "person.fill"
        case "family": return "person.2.fill"
        case "friends": return "person.3.fill"
        case "finance", "bills", "receipts": return "dollarsign.circle.fill"
        case "shopping", "purchases": return "bag.fill"
        case "travel", "flights", "trips": return "airplane"
        case "news": return "newspaper.fill"
        case "social": return "at"
        case "updates", "alerts": return "bell.badge.fill"
        case "promotions", "ads", "marketing": return "sparkles"
        case "github", "dev", "code", "engineering": return "chevron.left.slash.chevron.right"
        case "health", "medical": return "heart.fill"
        case "fitness", "exercise": return "figure.run"
        case "food", "restaurants": return "fork.knife"
        case "music": return "music.note"
        case "events", "calendar": return "calendar"
        case "education", "school": return "book.fill"
        case "utilities": return "wrench.and.screwdriver.fill"
        case "support", "tickets": return "lifepreserver"
        case "photos", "images": return "photo.fill.on.rectangle.fill"
        case "videos", "media": return "film.fill"
        case "security": return "lock.shield.fill"
        case "travel docs", "boarding": return "doc.plaintext.fill"
        default:
            let curated = [
                "bolt.fill","leaf.fill","globe","cloud.fill","sun.max.fill","moon.stars.fill","flame.fill",
                "paperplane.fill","envelope.fill","bookmark.fill","flag.fill","map.fill","pin.fill",
                "mappin.and.ellipse","location.fill","car.fill","tram.fill","bicycle","scooter","bus.fill",
                "train.side.front.car","ferry.fill","airpods.gen3","headphones","book.closed.fill",
                "doc.richtext.fill","doc.text.image","tray.full.fill","archivebox.fill","shippingbox.fill",
                "shippingbox.circle.fill","creditcard.fill","gift.fill","bag.badge.plus","cart.fill",
                "tag.fill","ticket.fill","theatermasks.fill","gamecontroller.fill","puzzlepiece.fill",
                "cpu.fill","antenna.radiowaves.left.and.right","network","wifi","bolt.horizontal.fill",
                "printer.fill","scanner.fill","signature","wand.and.stars","list.bullet.rectangle.fill",
                "chart.bar.fill","chart.pie.fill","chart.xyaxis.line","gauge.with.dots.needle.bottom.50percent",
                "speedometer","checkmark.seal.fill","star.circle.fill","medal.fill","rosette","trophy.fill",
                "sparkle.magnifyingglass","magnifyingglass","paperclip","link","shield.checkered",
                "hand.thumbsup.fill","hand.raised.fill","hands.sparkles.fill","message.fill","bubble.left.fill",
                "bubbles.and.sparkles.fill","bell.fill","bell.badge","bell.circle.fill","megaphone.fill",
                "mail.stack","calendar.badge.clock","clock.fill","alarm.fill","hourglass","tray.and.arrow.down.fill",
                "arrow.up.doc.fill","externaldrive.fill","internaldrive.fill","server.rack","folder.fill",
                "folder.badge.person.crop","folder.badge.gearshape","building.columns.fill","house.fill",
                "house.and.flag.fill","sparkles.square.fill","square.grid.2x2.fill","square.grid.3x1.below.rectangle.fill"
            ]
            let idx = abs(category.id.hashValue) % curated.count
            return curated[idx]
        }
    }

    private func color(for category: CategoryDTO) -> Color {
        if let hex = category.colorHex, let c = Color(hex: hex) {
            return c
        }
        let palette: [Color] = [
            Color(red: 0.93, green: 0.33, blue: 0.31),
            Color(red: 0.98, green: 0.62, blue: 0.20),
            Color(red: 1.00, green: 0.80, blue: 0.20),
            Color(red: 0.40, green: 0.76, blue: 0.65),
            Color(red: 0.20, green: 0.60, blue: 0.86),
            Color(red: 0.56, green: 0.47, blue: 0.80),
            Color(red: 0.55, green: 0.76, blue: 0.29),
            Color(red: 0.90, green: 0.49, blue: 0.13),
            Color(red: 0.67, green: 0.33, blue: 0.33),
            Color(red: 0.76, green: 0.21, blue: 0.48),
            Color(red: 0.35, green: 0.35, blue: 0.35),
            Color(red: 0.23, green: 0.50, blue: 0.43),
            Color(red: 0.12, green: 0.47, blue: 0.71),
            Color(red: 0.68, green: 0.78, blue: 0.28),
            Color(red: 0.40, green: 0.60, blue: 0.90),
            Color(red: 0.80, green: 0.70, blue: 0.90),
            Color(red: 1.00, green: 0.60, blue: 0.60),
            Color(red: 0.50, green: 0.80, blue: 0.80),
            Color(red: 0.90, green: 0.80, blue: 0.50),
            Color(red: 0.80, green: 0.50, blue: 0.60),
            Color(red: 0.70, green: 0.50, blue: 0.40),
            Color(red: 0.50, green: 0.70, blue: 0.50),
            Color(red: 0.60, green: 0.50, blue: 0.70),
            Color(red: 0.50, green: 0.60, blue: 0.80)
        ]
        let idx = abs(category.id.hashValue) % palette.count
        return palette[idx]
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
                        Circle()
                            .fill(color(for: c).opacity(0.25))
#if os(macOS)
                            .frame(width: 28, height: 28)
#else
                            .frame(width: 24, height: 24)
#endif
                        Image(systemName: iconName(for: c))
#if os(macOS)
                            .imageScale(.medium)
#else
                            .imageScale(.small)
#endif
                            .foregroundStyle(color(for: c))
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

    // Reuse helpers from InboxView with same logic
    private func iconName(for category: CategoryDTO) -> String {
        let name = category.name.lowercased()
        switch name {
        case "uncategorized", "none", "other": return "tray"
        case "work", "office": return "briefcase.fill"
        case "personal", "home": return "person.fill"
        case "family": return "person.2.fill"
        case "friends": return "person.3.fill"
        case "finance", "bills", "receipts": return "dollarsign.circle.fill"
        case "shopping", "purchases": return "bag.fill"
        case "travel", "flights", "trips": return "airplane"
        case "news": return "newspaper.fill"
        case "social": return "at"
        case "updates", "alerts": return "bell.badge.fill"
        case "promotions", "ads", "marketing": return "sparkles"
        case "github", "dev", "code", "engineering": return "chevron.left.slash.chevron.right"
        case "health", "medical": return "heart.fill"
        case "fitness", "exercise": return "figure.run"
        case "food", "restaurants": return "fork.knife"
        case "music": return "music.note"
        case "events", "calendar": return "calendar"
        case "education", "school": return "book.fill"
        case "utilities": return "wrench.and.screwdriver.fill"
        case "support", "tickets": return "lifepreserver"
        case "photos", "images": return "photo.fill.on.rectangle.fill"
        case "videos", "media": return "film.fill"
        case "security": return "lock.shield.fill"
        case "travel docs", "boarding": return "doc.plaintext.fill"
        default:
            let curated = [
                "bolt.fill","leaf.fill","globe","cloud.fill","sun.max.fill","moon.stars.fill","flame.fill",
                "paperplane.fill","envelope.fill","bookmark.fill","flag.fill","map.fill","pin.fill",
                "mappin.and.ellipse","location.fill","car.fill","tram.fill","bicycle","scooter","bus.fill",
                "train.side.front.car","ferry.fill","airpods.gen3","headphones","book.closed.fill",
                "doc.richtext.fill","doc.text.image","tray.full.fill","archivebox.fill","shippingbox.fill",
                "shippingbox.circle.fill","creditcard.fill","gift.fill","bag.badge.plus","cart.fill",
                "tag.fill","ticket.fill","theatermasks.fill","gamecontroller.fill","puzzlepiece.fill",
                "cpu.fill","antenna.radiowaves.left.and.right","network","wifi","bolt.horizontal.fill",
                "printer.fill","scanner.fill","signature","wand.and.stars","list.bullet.rectangle.fill",
                "chart.bar.fill","chart.pie.fill","chart.xyaxis.line","gauge.with.dots.needle.bottom.50percent",
                "speedometer","checkmark.seal.fill","star.circle.fill","medal.fill","rosette","trophy.fill",
                "sparkle.magnifyingglass","magnifyingglass","paperclip","link","shield.checkered",
                "hand.thumbsup.fill","hand.raised.fill","hands.sparkles.fill","message.fill","bubble.left.fill",
                "bubbles.and.sparkles.fill","bell.fill","bell.badge","bell.circle.fill","megaphone.fill",
                "mail.stack","calendar.badge.clock","clock.fill","alarm.fill","hourglass","tray.and.arrow.down.fill",
                "arrow.up.doc.fill","externaldrive.fill","internaldrive.fill","server.rack","folder.fill",
                "folder.badge.person.crop","folder.badge.gearshape","building.columns.fill","house.fill",
                "house.and.flag.fill","sparkles.square.fill","square.grid.2x2.fill","square.grid.3x1.below.rectangle.fill"
            ]
            let idx = abs(category.id.hashValue) % curated.count
            return curated[idx]
        }
    }

    private func color(for category: CategoryDTO) -> Color {
        if let hex = category.colorHex, let c = Color(hex: hex) {
            return c
        }
        let palette: [Color] = [
            Color(red: 0.93, green: 0.33, blue: 0.31),
            Color(red: 0.98, green: 0.62, blue: 0.20),
            Color(red: 1.00, green: 0.80, blue: 0.20),
            Color(red: 0.40, green: 0.76, blue: 0.65),
            Color(red: 0.20, green: 0.60, blue: 0.86),
            Color(red: 0.56, green: 0.47, blue: 0.80),
            Color(red: 0.55, green: 0.76, blue: 0.29),
            Color(red: 0.90, green: 0.49, blue: 0.13),
            Color(red: 0.67, green: 0.33, blue: 0.33),
            Color(red: 0.76, green: 0.21, blue: 0.48),
            Color(red: 0.35, green: 0.35, blue: 0.35),
            Color(red: 0.23, green: 0.50, blue: 0.43),
            Color(red: 0.12, green: 0.47, blue: 0.71),
            Color(red: 0.68, green: 0.78, blue: 0.28),
            Color(red: 0.40, green: 0.60, blue: 0.90),
            Color(red: 0.80, green: 0.70, blue: 0.90),
            Color(red: 1.00, green: 0.60, blue: 0.60),
            Color(red: 0.50, green: 0.80, blue: 0.80),
            Color(red: 0.90, green: 0.80, blue: 0.50),
            Color(red: 0.80, green: 0.50, blue: 0.60),
            Color(red: 0.70, green: 0.50, blue: 0.40),
            Color(red: 0.50, green: 0.70, blue: 0.50),
            Color(red: 0.60, green: 0.50, blue: 0.70),
            Color(red: 0.50, green: 0.60, blue: 0.80)
        ]
        let idx = abs(category.id.hashValue) % palette.count
        return palette[idx]
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
