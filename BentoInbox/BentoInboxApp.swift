//
//  BentoInboxApp.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import SwiftUI
import SwiftData

@main
struct BentoInboxApp: App {

    // Register our SwiftData models
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self,
            Category.self,
            TrainingExample.self,
            SyncState.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // App-wide services (mocked for now)
    @State private var appState = AppState()
    @State private var authService: AuthService = MockAuthService()
    @State private var gmailService: GmailService = MockGmailService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(\.authService, authService)
                .environment(\.gmailService, gmailService)
                .onAppear {
                    // no-op; real initialization later
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

