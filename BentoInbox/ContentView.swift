//
//  ContentView.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import SwiftUI
import SwiftData

// RootView decides whether to show SignIn or the Inbox based on auth state
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.authService) private var authService
    @Environment(\.modelContext) private var modelContext

    @State private var signInVM = SignInViewModel()
    @State private var inboxVM = InboxViewModel()

    var body: some View {
        Group {
            if appState.isSignedIn {
                InboxView(viewModel: inboxVM)
            } else {
                SignInView(viewModel: signInVM)
            }
        }
        .task {
            // On launch, check sign-in status
            appState.isSignedIn = await signInVM.checkSignedIn(authService: authService)
            if appState.isSignedIn {
                // Seed categories if needed
                try? SeedCategoryLoader.seedIfNeeded(modelContext)
            }
        }
    }
}

#Preview {
    // Preview with in-memory store and mocked services
    let container = try! ModelContainer(for: Message.self, Category.self, TrainingExample.self, SyncState.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let appState = AppState()
    appState.isSignedIn = true
    return RootView()
        .environment(appState)
        .environment(\.authService, MockAuthService())
        .environment(\.gmailService, MockGmailService())
        .modelContainer(container)
}
